-- Migration 0040: Add CHALLENGE_ID column to OTP_VERIFICATIONS & Update SPs for Challenge-based OTP Verification

-- 1. Add CHALLENGE_ID column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.OTP_VERIFICATIONS') AND name = 'CHALLENGE_ID')
BEGIN
    ALTER TABLE dbo.OTP_VERIFICATIONS 
    ADD CHALLENGE_ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID();

    CREATE UNIQUE NONCLUSTERED INDEX UQ_OTP_VERIFICATIONS_CHALLENGE_ID 
    ON dbo.OTP_VERIFICATIONS(CHALLENGE_ID);
END
GO

-- 2. Update PR_AUTH_CREATE_OTP_VERIFICATION to accept and return CHALLENGE_ID
CREATE OR ALTER PROCEDURE dbo.PR_AUTH_CREATE_OTP_VERIFICATION
    @CountryCode VARCHAR(10),
    @MobileNumber VARCHAR(20),
    @OtpHash VARCHAR(500),
    @OtpPurpose VARCHAR(30),
    @ExpiresAt DATETIME2,
    @MaxAttempts INT = 5,
    @MinResendIntervalSeconds INT = 60,
    @MaxResendLimit INT = 5,
    @ChallengeId UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LastCreatedAt DATETIME2;
    DECLARE @LastResendCount INT = 0;

    -- Check last OTP record for this mobile & purpose
    SELECT TOP 1 
        @LastCreatedAt = CREATED_AT,
        @LastResendCount = ISNULL(RESEND_COUNT, 0)
    FROM dbo.OTP_VERIFICATIONS
    WHERE COUNTRY_CODE = @CountryCode 
      AND MOBILE_NUMBER = @MobileNumber 
      AND OTP_PURPOSE = @OtpPurpose
    ORDER BY OTP_ID DESC;

    -- 1. Cooldown Protection: Check if created within last N seconds (60s)
    IF @LastCreatedAt IS NOT NULL AND DATEDIFF(SECOND, @LastCreatedAt, SYSUTCDATETIME()) < @MinResendIntervalSeconds
    BEGIN
        DECLARE @WaitSeconds INT = @MinResendIntervalSeconds - DATEDIFF(SECOND, @LastCreatedAt, SYSUTCDATETIME());
        DECLARE @ErrMsg NVARCHAR(250) = FORMATMESSAGE('Please wait %d seconds before requesting another OTP.', @WaitSeconds);
        RAISERROR(@ErrMsg, 16, 1);
        RETURN;
    END

    -- 2. Max Resend Limit: Check if resend count exceeded
    IF @LastResendCount >= @MaxResendLimit
    BEGIN
        IF DATEDIFF(MINUTE, @LastCreatedAt, SYSUTCDATETIME()) < 30
        BEGIN
            RAISERROR('Maximum OTP resend limit exceeded. Please try again after 30 minutes.', 16, 1);
            RETURN;
        END
        ELSE
        BEGIN
            SET @LastResendCount = 0;
        END
    END

    DECLARE @CurrentResendCount INT = @LastResendCount + 1;
    IF @ChallengeId IS NULL SET @ChallengeId = NEWID();

    -- Invalidate existing pending OTPs for this number and purpose
    UPDATE dbo.OTP_VERIFICATIONS
    SET OTP_STATUS = 'INVALIDATED',
        UPDATED_AT = SYSUTCDATETIME()
    WHERE COUNTRY_CODE = @CountryCode 
      AND MOBILE_NUMBER = @MobileNumber 
      AND OTP_PURPOSE = @OtpPurpose 
      AND OTP_STATUS = 'PENDING';

    -- Insert new OTP record with CHALLENGE_ID
    INSERT INTO dbo.OTP_VERIFICATIONS
    (
        CHALLENGE_ID,
        COUNTRY_CODE,
        MOBILE_NUMBER,
        OTP_HASH,
        OTP_PURPOSE,
        ATTEMPT_COUNT,
        RESEND_COUNT,
        MAX_ATTEMPTS,
        OTP_STATUS,
        EXPIRES_AT,
        CREATED_AT
    )
    VALUES
    (
        @ChallengeId,
        @CountryCode,
        @MobileNumber,
        @OtpHash,
        @OtpPurpose,
        0,
        @CurrentResendCount,
        @MaxAttempts,
        'PENDING',
        @ExpiresAt,
        SYSUTCDATETIME()
    );

    DECLARE @NewOtpId BIGINT = SCOPE_IDENTITY();

    SELECT @NewOtpId AS OtpId, @ChallengeId AS ChallengeId;
END;
GO

-- 3. Update PR_AUTH_VERIFY_OTP_AND_REGISTER_CUSTOMER to verify by CHALLENGE_ID or (CountryCode + Mobile)
CREATE OR ALTER PROCEDURE dbo.PR_AUTH_VERIFY_OTP_AND_REGISTER_CUSTOMER
    @CountryCode VARCHAR(10),
    @MobileNumber VARCHAR(20),
    @OtpHash VARCHAR(500),
    @FullName NVARCHAR(150) = NULL,
    @LanguageCode VARCHAR(10) = 'EN',
    @RefreshTokenHash VARCHAR(500),
    @DeviceId VARCHAR(200) = NULL,
    @DeviceType VARCHAR(30) = NULL,
    @IpAddress VARCHAR(45) = NULL,
    @SessionExpiresAt DATETIME2,
    @MaxAttempts INT = 5,
    @ChallengeId UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OtpId BIGINT;
    DECLARE @StoredOtpHash VARCHAR(500);
    DECLARE @AttemptCount INT;
    DECLARE @OtpExpiresAt DATETIME2;
    DECLARE @OtpStatus VARCHAR(20);

    IF @ChallengeId IS NOT NULL
    BEGIN
        SELECT TOP 1 
            @OtpId = OTP_ID,
            @StoredOtpHash = OTP_HASH,
            @AttemptCount = ATTEMPT_COUNT,
            @OtpExpiresAt = EXPIRES_AT,
            @OtpStatus = OTP_STATUS
        FROM dbo.OTP_VERIFICATIONS
        WHERE CHALLENGE_ID = @ChallengeId;
    END
    ELSE
    BEGIN
        SELECT TOP 1 
            @OtpId = OTP_ID,
            @StoredOtpHash = OTP_HASH,
            @AttemptCount = ATTEMPT_COUNT,
            @OtpExpiresAt = EXPIRES_AT,
            @OtpStatus = OTP_STATUS
        FROM dbo.OTP_VERIFICATIONS
        WHERE COUNTRY_CODE = @CountryCode 
          AND MOBILE_NUMBER = @MobileNumber 
          AND OTP_STATUS = 'PENDING'
        ORDER BY OTP_ID DESC;
    END

    IF @OtpId IS NULL OR @OtpExpiresAt < SYSUTCDATETIME() OR @OtpStatus = 'INVALIDATED'
    BEGIN
        RAISERROR('Invalid or expired OTP request. Please request a new OTP.', 16, 1);
        RETURN;
    END

    IF @OtpStatus = 'BLOCKED' OR @AttemptCount >= @MaxAttempts
    BEGIN
        UPDATE dbo.OTP_VERIFICATIONS
        SET OTP_STATUS = 'BLOCKED', UPDATED_AT = SYSUTCDATETIME()
        WHERE OTP_ID = @OtpId;

        RAISERROR('Maximum OTP verification attempts exceeded. Your OTP has been blocked.', 16, 1);
        RETURN;
    END

    -- Verify OTP Hash (BEFORE opening transaction so ATTEMPT_COUNT update persists)
    IF @StoredOtpHash <> @OtpHash
    BEGIN
        DECLARE @NewAttemptCount INT = @AttemptCount + 1;

        IF @NewAttemptCount >= @MaxAttempts
        BEGIN
            UPDATE dbo.OTP_VERIFICATIONS
            SET ATTEMPT_COUNT = @NewAttemptCount,
                OTP_STATUS = 'BLOCKED',
                UPDATED_AT = SYSUTCDATETIME()
            WHERE OTP_ID = @OtpId;

            RAISERROR('Maximum OTP verification attempts exceeded. Your OTP has been blocked.', 16, 1);
            RETURN;
        END
        ELSE
        BEGIN
            UPDATE dbo.OTP_VERIFICATIONS
            SET ATTEMPT_COUNT = @NewAttemptCount,
                UPDATED_AT = SYSUTCDATETIME()
            WHERE OTP_ID = @OtpId;

            RAISERROR('Invalid OTP code provided.', 16, 1);
            RETURN;
        END
    END

    -- OTP is valid -> Begin Transaction for User Registration & Session Creation
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Mark OTP Verified
        UPDATE dbo.OTP_VERIFICATIONS
        SET OTP_STATUS = 'VERIFIED',
            VERIFIED_AT = SYSUTCDATETIME(),
            UPDATED_AT = SYSUTCDATETIME()
        WHERE OTP_ID = @OtpId;

        -- Register/Login Customer logic
        DECLARE @UserId BIGINT;
        DECLARE @IsNewUser BIT = 0;
        DECLARE @UserRoleId BIGINT = 0;
        DECLARE @ActualFullName NVARCHAR(150);

        SELECT TOP 1 
            @UserId = USER_ID,
            @ActualFullName = FULL_NAME
        FROM dbo.USERS 
        WHERE COUNTRY_CODE = @CountryCode AND MOBILE_NUMBER = @MobileNumber;

        IF @UserId IS NULL
        BEGIN
            SET @IsNewUser = 1;
            SET @ActualFullName = ISNULL(NULLIF(@FullName, ''), 'Customer');

            INSERT INTO dbo.USERS
            (
                COUNTRY_CODE, MOBILE_NUMBER, FULL_NAME, LANGUAGE_CODE,
                IS_MOBILE_VERIFIED, IS_EMAIL_VERIFIED, IS_PROFILE_COMPLETED,
                USER_STATUS, LAST_LOGIN_AT, CREATED_AT
            )
            VALUES
            (
                @CountryCode, @MobileNumber, @ActualFullName, @LanguageCode,
                1, 0, 1, 'ACTIVE', SYSUTCDATETIME(), SYSUTCDATETIME()
            );

            SET @UserId = SCOPE_IDENTITY();

            DECLARE @RoleId INT;
            SELECT TOP 1 @RoleId = ROLE_ID FROM dbo.ROLES WHERE ROLE_CODE = 'CUSTOMER';
            IF @RoleId IS NULL RAISERROR('CUSTOMER role code not found.', 16, 1);

            INSERT INTO dbo.USER_ROLES (USER_ID, ROLE_ID, IS_ACTIVE, ASSIGNED_AT)
            VALUES (@UserId, @RoleId, 1, SYSUTCDATETIME());

            SET @UserRoleId = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            IF @FullName IS NOT NULL AND @FullName <> ''
            BEGIN
                SET @ActualFullName = @FullName;
                UPDATE dbo.USERS
                SET FULL_NAME = @FullName, LAST_LOGIN_AT = SYSUTCDATETIME(), IS_MOBILE_VERIFIED = 1, UPDATED_AT = SYSUTCDATETIME()
                WHERE USER_ID = @UserId;
            END
            ELSE
            BEGIN
                UPDATE dbo.USERS
                SET LAST_LOGIN_AT = SYSUTCDATETIME(), IS_MOBILE_VERIFIED = 1, UPDATED_AT = SYSUTCDATETIME()
                WHERE USER_ID = @UserId;
            END
        END

        INSERT INTO dbo.USER_SESSIONS
        (
            USER_ID, REFRESH_TOKEN_HASH, DEVICE_ID, DEVICE_TYPE, IP_ADDRESS, IS_ACTIVE, EXPIRES_AT, CREATED_AT
        )
        VALUES
        (
            @UserId, @RefreshTokenHash, @DeviceId, @DeviceType, @IpAddress, 1, @SessionExpiresAt, SYSUTCDATETIME()
        );

        DECLARE @SessionId BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT 
            @UserId AS UserId,
            @UserRoleId AS UserRoleId,
            @SessionId AS SessionId,
            @IsNewUser AS IsNewUser,
            @ActualFullName AS FullName;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO
