-- Migration 0036: Stored Procedures for OTP and Registration Flow

-- 1. Check if Mobile Already Registered
CREATE OR ALTER PROCEDURE dbo.usp_Auth_CheckMobileExists
    @CountryCode VARCHAR(10),
    @MobileNumber VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT CASE WHEN EXISTS (
        SELECT 1 FROM dbo.USERS 
        WHERE COUNTRY_CODE = @CountryCode AND MOBILE_NUMBER = @MobileNumber
    ) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS MobileExists;
END;
GO

-- 2. Create OTP Verification Entry
CREATE OR ALTER PROCEDURE dbo.usp_Auth_CreateOtpVerification
    @CountryCode VARCHAR(10),
    @MobileNumber VARCHAR(20),
    @OtpHash VARCHAR(500),
    @OtpPurpose VARCHAR(30),
    @ExpiresAt DATETIME2,
    @MaxAttempts INT = 5
AS
BEGIN
    SET NOCOUNT ON;

    -- Invalidate existing pending OTPs for this number and purpose
    UPDATE dbo.OTP_VERIFICATIONS
    SET OTP_STATUS = 'INVALIDATED',
        UPDATED_AT = SYSUTCDATETIME()
    WHERE COUNTRY_CODE = @CountryCode 
      AND MOBILE_NUMBER = @MobileNumber 
      AND OTP_PURPOSE = @OtpPurpose 
      AND OTP_STATUS = 'PENDING';

    -- Insert new OTP record
    INSERT INTO dbo.OTP_VERIFICATIONS
    (
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
        @CountryCode,
        @MobileNumber,
        @OtpHash,
        @OtpPurpose,
        0,
        0,
        @MaxAttempts,
        'PENDING',
        @ExpiresAt,
        SYSUTCDATETIME()
    );

    SELECT SCOPE_IDENTITY() AS OtpId;
END;
GO

-- 3. Get Latest Pending OTP Verification
CREATE OR ALTER PROCEDURE dbo.usp_Auth_GetLatestPendingOtp
    @CountryCode VARCHAR(10),
    @MobileNumber VARCHAR(20),
    @OtpPurpose VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 
        OTP_ID AS OtpId,
        USER_ID AS UserId,
        COUNTRY_CODE AS CountryCode,
        MOBILE_NUMBER AS MobileNumber,
        OTP_HASH AS OtpHash,
        OTP_PURPOSE AS OtpPurpose,
        ATTEMPT_COUNT AS AttemptCount,
        RESEND_COUNT AS ResendCount,
        MAX_ATTEMPTS AS MaxAttempts,
        OTP_STATUS AS OtpStatus,
        EXPIRES_AT AS ExpiresAt,
        VERIFIED_AT AS VerifiedAt,
        CREATED_AT AS CreatedAt
    FROM dbo.OTP_VERIFICATIONS
    WHERE COUNTRY_CODE = @CountryCode 
      AND MOBILE_NUMBER = @MobileNumber 
      AND OTP_PURPOSE = @OtpPurpose 
      AND OTP_STATUS = 'PENDING'
    ORDER BY OTP_ID DESC;
END;
GO

-- 4. Update OTP Status and Increment Attempts
CREATE OR ALTER PROCEDURE dbo.usp_Auth_UpdateOtpStatus
    @OtpId BIGINT,
    @OtpStatus VARCHAR(20),
    @IncrementAttempt BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.OTP_VERIFICATIONS
    SET OTP_STATUS = @OtpStatus,
        ATTEMPT_COUNT = CASE WHEN @IncrementAttempt = 1 THEN ATTEMPT_COUNT + 1 ELSE ATTEMPT_COUNT END,
        VERIFIED_AT = CASE WHEN @OtpStatus = 'VERIFIED' THEN SYSUTCDATETIME() ELSE VERIFIED_AT END,
        UPDATED_AT = SYSUTCDATETIME()
    WHERE OTP_ID = @OtpId;
END;
GO

-- 5. Register or Login Customer, Assign Role, and Create Session
CREATE OR ALTER PROCEDURE dbo.usp_Auth_RegisterCustomerAndSession
    @CountryCode VARCHAR(10),
    @MobileNumber VARCHAR(20),
    @FullName NVARCHAR(150) = NULL,
    @LanguageCode VARCHAR(10) = 'EN',
    @RefreshTokenHash VARCHAR(500),
    @DeviceId VARCHAR(200) = NULL,
    @DeviceType VARCHAR(30) = NULL,
    @IpAddress VARCHAR(45) = NULL,
    @SessionExpiresAt DATETIME2
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @UserId BIGINT;
        DECLARE @IsNewUser BIT = 0;
        DECLARE @UserRoleId BIGINT = 0;
        DECLARE @ActualFullName NVARCHAR(150);

        -- Check if User exists
        SELECT TOP 1 
            @UserId = USER_ID,
            @ActualFullName = FULL_NAME
        FROM dbo.USERS 
        WHERE COUNTRY_CODE = @CountryCode AND MOBILE_NUMBER = @MobileNumber;

        IF @UserId IS NULL
        BEGIN
            -- User DOES NOT EXIST -> Create New User
            SET @IsNewUser = 1;
            SET @ActualFullName = ISNULL(NULLIF(@FullName, ''), 'Customer');

            INSERT INTO dbo.USERS
            (
                COUNTRY_CODE,
                MOBILE_NUMBER,
                FULL_NAME,
                LANGUAGE_CODE,
                IS_MOBILE_VERIFIED,
                IS_EMAIL_VERIFIED,
                IS_PROFILE_COMPLETED,
                USER_STATUS,
                LAST_LOGIN_AT,
                CREATED_AT
            )
            VALUES
            (
                @CountryCode,
                @MobileNumber,
                @ActualFullName,
                @LanguageCode,
                1, -- Verified via OTP
                0,
                1,
                'ACTIVE',
                SYSUTCDATETIME(),
                SYSUTCDATETIME()
            );

            SET @UserId = SCOPE_IDENTITY();

            -- Get CUSTOMER Role ID
            DECLARE @RoleId INT;
            SELECT TOP 1 @RoleId = ROLE_ID FROM dbo.ROLES WHERE ROLE_CODE = 'CUSTOMER';

            IF @RoleId IS NULL
            BEGIN
                RAISERROR('CUSTOMER role code not found.', 16, 1);
            END

            -- Assign CUSTOMER Role
            INSERT INTO dbo.USER_ROLES (USER_ID, ROLE_ID, IS_ACTIVE, ASSIGNED_AT)
            VALUES (@UserId, @RoleId, 1, SYSUTCDATETIME());

            SET @UserRoleId = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            -- User EXISTS -> Update last login time & full name if provided
            IF @FullName IS NOT NULL AND @FullName <> ''
            BEGIN
                SET @ActualFullName = @FullName;
                UPDATE dbo.USERS
                SET FULL_NAME = @FullName,
                    LAST_LOGIN_AT = SYSUTCDATETIME(),
                    IS_MOBILE_VERIFIED = 1,
                    UPDATED_AT = SYSUTCDATETIME()
                WHERE USER_ID = @UserId;
            END
            ELSE
            BEGIN
                UPDATE dbo.USERS
                SET LAST_LOGIN_AT = SYSUTCDATETIME(),
                    IS_MOBILE_VERIFIED = 1,
                    UPDATED_AT = SYSUTCDATETIME()
                WHERE USER_ID = @UserId;
            END
        END

        -- Create User Session
        INSERT INTO dbo.USER_SESSIONS
        (
            USER_ID,
            REFRESH_TOKEN_HASH,
            DEVICE_ID,
            DEVICE_TYPE,
            IP_ADDRESS,
            IS_ACTIVE,
            EXPIRES_AT,
            CREATED_AT
        )
        VALUES
        (
            @UserId,
            @RefreshTokenHash,
            @DeviceId,
            @DeviceType,
            @IpAddress,
            1,
            @SessionExpiresAt,
            SYSUTCDATETIME()
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
