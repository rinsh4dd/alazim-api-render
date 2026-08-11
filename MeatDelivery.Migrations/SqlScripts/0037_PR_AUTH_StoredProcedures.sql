-- Migration 0037: Drop legacy usp_ procedures and create ALL CAPS PR_AUTH_ stored procedures

-- Drop old usp_ procedures
IF OBJECT_ID('dbo.usp_Auth_CheckMobileExists', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Auth_CheckMobileExists;
IF OBJECT_ID('dbo.usp_Auth_CreateOtpVerification', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Auth_CreateOtpVerification;
IF OBJECT_ID('dbo.usp_Auth_GetLatestPendingOtp', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Auth_GetLatestPendingOtp;
IF OBJECT_ID('dbo.usp_Auth_UpdateOtpStatus', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Auth_UpdateOtpStatus;
IF OBJECT_ID('dbo.usp_Auth_RegisterCustomerAndSession', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Auth_RegisterCustomerAndSession;
IF OBJECT_ID('dbo.usp_Auth_GetUserByUsername', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Auth_GetUserByUsername;
IF OBJECT_ID('dbo.usp_Auth_GetUserContext', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Auth_GetUserContext;
IF OBJECT_ID('dbo.usp_Auth_CreateUser', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Auth_CreateUser;
IF OBJECT_ID('dbo.usp_Auth_SaveRefreshToken', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Auth_SaveRefreshToken;
IF OBJECT_ID('dbo.usp_Auth_ValidateRefreshToken', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Auth_ValidateRefreshToken;
IF OBJECT_ID('dbo.usp_Auth_RevokeRefreshToken', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Auth_RevokeRefreshToken;
IF OBJECT_ID('dbo.usp_Auth_RevokeAllRefreshTokensByUserId', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Auth_RevokeAllRefreshTokensByUserId;
IF OBJECT_ID('dbo.usp_Auth_GetRolePermissions', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Auth_GetRolePermissions;
GO

-- 1. Check if Mobile Already Registered
CREATE OR ALTER PROCEDURE dbo.PR_AUTH_CHECK_MOBILE_EXISTS
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

-- 2. Create OTP Verification Entry with Cooldown and Resend Limits
CREATE OR ALTER PROCEDURE dbo.PR_AUTH_CREATE_OTP_VERIFICATION
    @CountryCode VARCHAR(10),
    @MobileNumber VARCHAR(20),
    @OtpHash VARCHAR(500),
    @OtpPurpose VARCHAR(30),
    @ExpiresAt DATETIME2,
    @MaxAttempts INT = 5,
    @MinResendIntervalSeconds INT = 60,
    @MaxResendLimit INT = 5
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

    -- 1. Cooldown Protection: Check if created within last N seconds (e.g. 60 seconds)
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
        @CurrentResendCount,
        @MaxAttempts,
        'PENDING',
        @ExpiresAt,
        SYSUTCDATETIME()
    );

    SELECT SCOPE_IDENTITY() AS OtpId;
END;
GO

-- 3. Get Latest Pending O  TP Verification
CREATE OR ALTER PROCEDURE dbo.PR_AUTH_GET_LATEST_PENDING_OTP
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
CREATE OR ALTER PROCEDURE dbo.PR_AUTH_UPDATE_OTP_STATUS
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
CREATE OR ALTER PROCEDURE dbo.PR_AUTH_REGISTER_CUSTOMER_AND_SESSION
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
                1,
                0,
                1,
                'ACTIVE',
                SYSUTCDATETIME(),
                SYSUTCDATETIME()
            );

            SET @UserId = SCOPE_IDENTITY();

            DECLARE @RoleId INT;
            SELECT TOP 1 @RoleId = ROLE_ID FROM dbo.ROLES WHERE ROLE_CODE = 'CUSTOMER';

            IF @RoleId IS NULL
            BEGIN
                RAISERROR('CUSTOMER role code not found.', 16, 1);
            END

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

-- 6. Verify OTP, Register/Login Customer, Assign Role, Create Session in ONE Atomic Procedure
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

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @OtpId BIGINT;
        DECLARE @StoredOtpHash VARCHAR(500);
        DECLARE @AttemptCount INT;
        DECLARE @OtpExpiresAt DATETIME2;

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
        END

        IF @AttemptCount >= @MaxAttempts
        BEGIN
            UPDATE dbo.OTP_VERIFICATIONS
            SET OTP_STATUS = 'BLOCKED', UPDATED_AT = SYSUTCDATETIME()
            WHERE OTP_ID = @OtpId;

            RAISERROR('Maximum OTP verification attempts exceeded.', 16, 1);
        END

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
            END
            ELSE
            BEGIN
                UPDATE dbo.OTP_VERIFICATIONS
                SET ATTEMPT_COUNT = @NewAttemptCount,
                    UPDATED_AT = SYSUTCDATETIME()
                WHERE OTP_ID = @OtpId;

                RAISERROR('Invalid OTP code provided.', 16, 1);
            END
        END

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

-- 7. Refresh Token Session Flow in SP
CREATE OR ALTER PROCEDURE dbo.PR_AUTH_REFRESH_TOKEN_SESSION
    @CountryCode VARCHAR(10),
    @MobileNumber VARCHAR(20),
    @OldRefreshTokenHash VARCHAR(500),
    @NewRefreshTokenHash VARCHAR(500),
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
        DECLARE @FullName NVARCHAR(150);

        SELECT TOP 1 
            @UserId = USER_ID,
            @FullName = FULL_NAME
        FROM dbo.USERS
        WHERE COUNTRY_CODE = @CountryCode AND MOBILE_NUMBER = @MobileNumber;

        IF @UserId IS NULL
        BEGIN
            RAISERROR('Invalid user or mobile number.', 16, 1);
        END

        DECLARE @OldSessionId BIGINT;
        DECLARE @OldDeviceId VARCHAR(200);
        DECLARE @OldDeviceType VARCHAR(30);

        SELECT TOP 1
            @OldSessionId = SESSION_ID,
            @OldDeviceId = DEVICE_ID,
            @OldDeviceType = DEVICE_TYPE
        FROM dbo.USER_SESSIONS
        WHERE USER_ID = @UserId 
          AND REFRESH_TOKEN_HASH = @OldRefreshTokenHash 
          AND IS_ACTIVE = 1 
          AND EXPIRES_AT > SYSUTCDATETIME();

        IF @OldSessionId IS NULL
        BEGIN
            RAISERROR('Invalid or expired refresh token session.', 16, 1);
        END

        -- Revoke Old Session
        UPDATE dbo.USER_SESSIONS
        SET IS_ACTIVE = 0, UPDATED_AT = SYSUTCDATETIME()
        WHERE SESSION_ID = @OldSessionId;

        -- Create New Session
        INSERT INTO dbo.USER_SESSIONS
        (
            USER_ID, REFRESH_TOKEN_HASH, DEVICE_ID, DEVICE_TYPE, IP_ADDRESS, IS_ACTIVE, EXPIRES_AT, CREATED_AT
        )
        VALUES
        (
            @UserId,
            @NewRefreshTokenHash,
            ISNULL(@DeviceId, @OldDeviceId),
            ISNULL(@DeviceType, @OldDeviceType),
            @IpAddress,
            1,
            @SessionExpiresAt,
            SYSUTCDATETIME()
        );

        DECLARE @NewSessionId BIGINT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT 
            @UserId AS UserId,
            @FullName AS FullName,
            @CountryCode AS CountryCode,
            @MobileNumber AS MobileNumber,
            @NewSessionId AS SessionId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO

-- 8. Logout Session
CREATE OR ALTER PROCEDURE dbo.PR_AUTH_LOGOUT_SESSION
    @CountryCode VARCHAR(10),
    @MobileNumber VARCHAR(20),
    @RefreshTokenHash VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE S
    SET S.IS_ACTIVE = 0,
        S.UPDATED_AT = SYSUTCDATETIME()
    FROM dbo.USER_SESSIONS S
    INNER JOIN dbo.USERS U ON U.USER_ID = S.USER_ID
    WHERE U.COUNTRY_CODE = @CountryCode 
      AND U.MOBILE_NUMBER = @MobileNumber 
      AND S.REFRESH_TOKEN_HASH = @RefreshTokenHash;
END;
GO

-- 9. Revoke All Sessions by User ID
CREATE OR ALTER PROCEDURE dbo.PR_AUTH_REVOKE_ALL_SESSIONS
    @UserId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.USER_SESSIONS
    SET IS_ACTIVE = 0,
        UPDATED_AT = SYSUTCDATETIME()
    WHERE USER_ID = @UserId AND IS_ACTIVE = 1;
END;
GO

-- 10. Get Role Permissions
CREATE OR ALTER PROCEDURE dbo.PR_AUTH_GET_ROLE_PERMISSIONS
    @RoleId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT P.PERMISSION_NAME
    FROM dbo.ROLE_PERMISSIONS RP
    INNER JOIN dbo.PERMISSIONS P ON P.PERMISSION_ID = RP.PERMISSION_ID
    WHERE RP.ROLE_ID = @RoleId;
END;
GO
