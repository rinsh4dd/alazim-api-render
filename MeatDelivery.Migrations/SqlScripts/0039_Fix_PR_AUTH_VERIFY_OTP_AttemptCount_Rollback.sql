-- Migration 0039: Fix ATTEMPT_COUNT rollback on wrong OTP verification

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
    @MaxAttempts INT = 5
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OtpId BIGINT;
    DECLARE @StoredOtpHash VARCHAR(500);
    DECLARE @AttemptCount INT;
    DECLARE @OtpExpiresAt DATETIME2;

    -- 1. Get latest pending OTP
    SELECT TOP 1 
        @OtpId = OTP_ID,
        @StoredOtpHash = OTP_HASH,
        @AttemptCount = ATTEMPT_COUNT,
        @OtpExpiresAt = EXPIRES_AT
    FROM dbo.OTP_VERIFICATIONS
    WHERE COUNTRY_CODE = @CountryCode 
      AND MOBILE_NUMBER = @MobileNumber 
      AND OTP_STATUS = 'PENDING'
    ORDER BY OTP_ID DESC;

    IF @OtpId IS NULL OR @OtpExpiresAt < SYSUTCDATETIME()
    BEGIN
        RAISERROR('Invalid or expired OTP request. Please request a new OTP.', 16, 1);
        RETURN;
    END

    IF @AttemptCount >= @MaxAttempts
    BEGIN
        UPDATE dbo.OTP_VERIFICATIONS
        SET OTP_STATUS = 'BLOCKED', UPDATED_AT = SYSUTCDATETIME()
        WHERE OTP_ID = @OtpId;

        RAISERROR('Maximum OTP verification attempts exceeded. Your OTP has been blocked.', 16, 1);
        RETURN;
    END

    -- 2. Verify OTP Hash (performed BEFORE opening transaction so ATTEMPT_COUNT update persists)
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

    -- 3. OTP is valid -> Begin Transaction for User Registration & Session Creation
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
