-- =============================================================================
-- Migration: 0005_Rename_Customer_Users_And_Create_Admin_Users.sql
-- Description:
-- 1. Renames dbo.USERS to dbo.CUSTOMER_USERS (Customer accounts only)
-- 2. Removes PASSWORD_HASH from CUSTOMER_USERS (OTP auth only)
-- 3. Creates dbo.ADMIN_USERS table for back-office admin accounts
-- 4. Updates all Customer Stored Procedures to reference dbo.CUSTOMER_USERS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. RENAME dbo.USERS TO dbo.CUSTOMER_USERS (OR CREATE IF FRESH)
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.CUSTOMER_USERS', 'U') IS NULL
BEGIN
    IF OBJECT_ID('dbo.USERS', 'U') IS NOT NULL
    BEGIN
        EXEC sp_rename 'dbo.USERS', 'CUSTOMER_USERS';
    END
    ELSE
    BEGIN
        CREATE TABLE dbo.CUSTOMER_USERS
        (
            USER_ID BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
            DOCTYPE VARCHAR(10) NULL,
            DOC_NO VARCHAR(30) NULL,
            COUNTRY_CODE VARCHAR(10) NOT NULL,
            MOBILE_NUMBER VARCHAR(20) NOT NULL,
            EMAIL VARCHAR(150) NULL,
            FIRST_NAME NVARCHAR(100) NULL,
            LAST_NAME NVARCHAR(100) NULL,
            DOB DATE NULL,
            GENDER VARCHAR(20) NULL,
            PROFILE_IMAGE_URL VARCHAR(500) NULL,
            LANGUAGE_CODE VARCHAR(10) NOT NULL DEFAULT 'EN',
            IS_MOBILE_VERIFIED BIT NOT NULL DEFAULT 0,
            IS_EMAIL_VERIFIED BIT NOT NULL DEFAULT 0,
            ELIGIBLE_FOR_ORDER BIT NOT NULL DEFAULT 0,
            IS_PROFILE_COMPLETED BIT NOT NULL DEFAULT 0,
            USER_STATUS VARCHAR(20) NOT NULL DEFAULT 'PENDING',
            LAST_LOGIN_AT DATETIME2 NULL,
            CREATED_AT DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
            UPDATED_AT DATETIME2 NULL,
            CONSTRAINT UQ_CUSTOMER_USERS_MOBILE UNIQUE (COUNTRY_CODE, MOBILE_NUMBER)
        );

        CREATE UNIQUE NONCLUSTERED INDEX UQ_CUSTOMER_USERS_EMAIL 
        ON dbo.CUSTOMER_USERS(EMAIL) 
        WHERE EMAIL IS NOT NULL;
    END
END
GO

-- -----------------------------------------------------------------------------
-- 2. ENSURE PASSWORD_HASH IS REMOVED FROM CUSTOMER_USERS (OTP ONLY)
-- -----------------------------------------------------------------------------
IF EXISTS (
    SELECT 1 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID('dbo.CUSTOMER_USERS') 
      AND name = 'PASSWORD_HASH'
)
BEGIN
    ALTER TABLE dbo.CUSTOMER_USERS DROP COLUMN PASSWORD_HASH;
END
GO

-- Ensure backward-compatible View for USERS if any legacy code queries it
CREATE OR ALTER VIEW dbo.USERS
AS
SELECT 
    USER_ID,
    DOCTYPE,
    DOC_NO,
    COUNTRY_CODE,
    MOBILE_NUMBER,
    EMAIL,
    FIRST_NAME,
    LAST_NAME,
    DOB,
    GENDER,
    PROFILE_IMAGE_URL,
    LANGUAGE_CODE,
    IS_MOBILE_VERIFIED,
    IS_EMAIL_VERIFIED,
    ELIGIBLE_FOR_ORDER,
    IS_PROFILE_COMPLETED,
    USER_STATUS,
    LAST_LOGIN_AT,
    CREATED_AT,
    UPDATED_AT
FROM dbo.CUSTOMER_USERS;
GO

-- -----------------------------------------------------------------------------
-- 3. CREATE dbo.ADMIN_USERS TABLE
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.ADMIN_USERS', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ADMIN_USERS
    (
        ADMIN_USER_ID BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        EMAIL VARCHAR(150) NOT NULL,
        PASSWORD_HASH VARCHAR(500) NOT NULL,
        FIRST_NAME NVARCHAR(100) NOT NULL,
        LAST_NAME NVARCHAR(100) NULL,
        COUNTRY_CODE VARCHAR(10) NULL,
        MOBILE_NUMBER VARCHAR(20) NULL,
        PROFILE_IMAGE_URL VARCHAR(500) NULL,
        ADMIN_STATUS VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
        FAILED_LOGIN_COUNT INT NOT NULL DEFAULT 0,
        LOCKED_UNTIL DATETIME2 NULL,
        LAST_LOGIN_AT DATETIME2 NULL,
        PASSWORD_CHANGED_AT DATETIME2 NULL,
        CREATED_BY_ADMIN_USER_ID BIGINT NULL,
        CREATED_AT DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UPDATED_AT DATETIME2 NULL,
        CONSTRAINT FK_ADMIN_USERS_CREATED_BY FOREIGN KEY (CREATED_BY_ADMIN_USER_ID) REFERENCES dbo.ADMIN_USERS(ADMIN_USER_ID)
    );

    CREATE UNIQUE NONCLUSTERED INDEX UQ_ADMIN_USERS_EMAIL 
    ON dbo.ADMIN_USERS(EMAIL);
END
GO

-- -----------------------------------------------------------------------------
-- 4. UPDATE STORED PROCEDURE: PR_AUTH_VERIFY_OTP_AND_REGISTER_CUSTOMER
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_AUTH_VERIFY_OTP_AND_REGISTER_CUSTOMER
    @CHALLENGE_ID UNIQUEIDENTIFIER,
    @COUNTRY_CODE VARCHAR(10),
    @MOBILE_NUMBER VARCHAR(20),
    @OTP_CODE VARCHAR(10),
    @DEVICE_ID VARCHAR(200),
    @DEVICE_TYPE VARCHAR(30),
    @IP_ADDRESS VARCHAR(45),
    @NEW_REFRESH_TOKEN_HASH VARCHAR(500),
    @REFRESH_TOKEN_EXPIRES_AT DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CurrentUtc DATETIME2 = SYSUTCDATETIME();
        DECLARE @OtpId BIGINT;
        DECLARE @OtpHash VARCHAR(500);
        DECLARE @OtpStatus VARCHAR(20);
        DECLARE @ExpiresAt DATETIME2;
        DECLARE @AttemptCount INT;
        DECLARE @MaxAttempts INT;
        DECLARE @RateLimitWindowStartAt DATETIME2;

        SELECT 
            @OtpId = OTP_ID,
            @OtpHash = OTP_HASH,
            @OtpStatus = OTP_STATUS,
            @ExpiresAt = EXPIRES_AT,
            @AttemptCount = ATTEMPT_COUNT,
            @MaxAttempts = MAX_ATTEMPTS,
            @RateLimitWindowStartAt = RATE_LIMIT_WINDOW_START_AT
        FROM dbo.OTP_VERIFICATIONS WITH (UPDLOCK, ROWLOCK)
        WHERE CHALLENGE_ID = @CHALLENGE_ID
          AND COUNTRY_CODE = @COUNTRY_CODE
          AND MOBILE_NUMBER = @MOBILE_NUMBER;

        IF @OtpId IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR('Invalid verification session. Please request a new OTP.', 16, 1);
            RETURN;
        END

        IF @OtpStatus <> 'PENDING'
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR('This OTP has already been processed or is no longer valid.', 16, 1);
            RETURN;
        END

        IF @CurrentUtc > @ExpiresAt
        BEGIN
            UPDATE dbo.OTP_VERIFICATIONS
            SET OTP_STATUS = 'EXPIRED', UPDATED_AT = @CurrentUtc
            WHERE OTP_ID = @OtpId;

            ROLLBACK TRANSACTION;
            RAISERROR('OTP code has expired. Please request a new one.', 16, 1);
            RETURN;
        END

        IF @AttemptCount >= @MaxAttempts
        BEGIN
            UPDATE dbo.OTP_VERIFICATIONS
            SET OTP_STATUS = 'BLOCKED', UPDATED_AT = @CurrentUtc
            WHERE OTP_ID = @OtpId;

            ROLLBACK TRANSACTION;
            RAISERROR('Maximum verification attempts exceeded. Please request a new OTP.', 16, 1);
            RETURN;
        END

        -- Verify Hash (SHA-256)
        DECLARE @ComputedOtpHash VARCHAR(500) = CONVERT(VARCHAR(500), HASHBYTES('SHA2_256', @OTP_CODE), 2);
        IF @ComputedOtpHash <> @OtpHash
        BEGIN
            UPDATE dbo.OTP_VERIFICATIONS
            SET ATTEMPT_COUNT = ATTEMPT_COUNT + 1,
                UPDATED_AT = @CurrentUtc
            WHERE OTP_ID = @OtpId;

            COMMIT TRANSACTION;
            RAISERROR('Incorrect verification code.', 16, 1);
            RETURN;
        END

        -- Mark OTP Verified
        UPDATE dbo.OTP_VERIFICATIONS
        SET OTP_STATUS = 'VERIFIED',
            VERIFIED_AT = @CurrentUtc,
            UPDATED_AT = @CurrentUtc
        WHERE OTP_ID = @OtpId;

        -- Check Customer User in dbo.CUSTOMER_USERS
        DECLARE @UserId BIGINT;
        DECLARE @IsNewUser BIT = 0;
        DECLARE @FirstName NVARCHAR(100);
        DECLARE @LastName NVARCHAR(100);
        DECLARE @FullName NVARCHAR(200);
        DECLARE @EligibleForOrder BIT = 0;
        DECLARE @IsProfileCompleted BIT = 0;
        DECLARE @AllocatedDocNo VARCHAR(30) = NULL;

        SELECT 
            @UserId = USER_ID,
            @FirstName = FIRST_NAME,
            @LastName = LAST_NAME,
            @EligibleForOrder = ELIGIBLE_FOR_ORDER,
            @IsProfileCompleted = IS_PROFILE_COMPLETED
        FROM dbo.CUSTOMER_USERS WITH (UPDLOCK, ROWLOCK)
        WHERE COUNTRY_CODE = @COUNTRY_CODE AND MOBILE_NUMBER = @MOBILE_NUMBER;

        IF @UserId IS NULL
        BEGIN
            SET @IsNewUser = 1;
            SET @EligibleForOrder = 0;
            SET @IsProfileCompleted = 0;

            -- Allocate CUST Document Number
            EXEC dbo.PR_DOC_ALLOCATE_NEXT_NO
                @DOC_TYPE = 'CUST',
                @DOC_NO = @AllocatedDocNo OUTPUT;

            INSERT INTO dbo.CUSTOMER_USERS 
            (
                DOCTYPE,
                DOC_NO,
                COUNTRY_CODE, 
                MOBILE_NUMBER, 
                IS_MOBILE_VERIFIED, 
                ELIGIBLE_FOR_ORDER,
                IS_PROFILE_COMPLETED,
                USER_STATUS, 
                LAST_LOGIN_AT, 
                CREATED_AT
            )
            VALUES 
            (
                'CUST',
                @AllocatedDocNo,
                @COUNTRY_CODE, 
                @MOBILE_NUMBER, 
                1, 
                0,
                0,
                'ACTIVE', 
                @CurrentUtc, 
                @CurrentUtc
            );

            SET @UserId = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE dbo.CUSTOMER_USERS
            SET IS_MOBILE_VERIFIED = 1,
                USER_STATUS = CASE WHEN USER_STATUS = 'PENDING' THEN 'ACTIVE' ELSE USER_STATUS END,
                LAST_LOGIN_AT = @CurrentUtc,
                UPDATED_AT = @CurrentUtc
            WHERE USER_ID = @UserId;
        END

        SET @FullName = ISNULL(LTRIM(RTRIM(ISNULL(@FirstName, '') + ' ' + ISNULL(@LastName, ''))), '');

        -- Link OTP to Customer User ID
        UPDATE dbo.OTP_VERIFICATIONS
        SET USER_ID = @UserId
        WHERE OTP_ID = @OtpId;

        -- Create Refresh Session
        DECLARE @SessionId BIGINT;
        INSERT INTO dbo.USER_SESSIONS
        (
            USER_ID,
            REFRESH_TOKEN_HASH,
            DEVICE_ID,
            DEVICE_TYPE,
            IP_ADDRESS,
            IS_ACTIVE,
            EXPIRES_AT,
            LAST_ACTIVITY_AT,
            CREATED_AT
        )
        VALUES
        (
            @UserId,
            @NEW_REFRESH_TOKEN_HASH,
            @DEVICE_ID,
            @DEVICE_TYPE,
            @IP_ADDRESS,
            1,
            @REFRESH_TOKEN_EXPIRES_AT,
            @CurrentUtc,
            @CurrentUtc
        );
        SET @SessionId = SCOPE_IDENTITY();

        -- Activity Log
        INSERT INTO dbo.ACTIVITY_LOGS
        (
            USER_ID,
            ACTIVITY_TYPE,
            DESCRIPTION,
            IP_ADDRESS,
            DEVICE_ID,
            DEVICE_TYPE,
            CREATED_AT
        )
        VALUES
        (
            @UserId,
            CASE WHEN @IsNewUser = 1 THEN 'CUSTOMER_REGISTER' ELSE 'CUSTOMER_LOGIN' END,
            CASE WHEN @IsNewUser = 1 THEN 'New customer registered via mobile OTP verification' ELSE 'Customer logged in via mobile OTP' END,
            @IP_ADDRESS,
            @DEVICE_ID,
            @DEVICE_TYPE,
            @CurrentUtc
        );

        COMMIT TRANSACTION;

        -- Return Customer payload
        SELECT 
            @UserId AS UserId,
            @IsNewUser AS IsNewUser,
            @FirstName AS FirstName,
            @LastName AS LastName,
            @FullName AS FullName,
            @COUNTRY_CODE AS CountryCode,
            @MOBILE_NUMBER AS MobileNumber,
            @EligibleForOrder AS EligibleForOrder,
            @IsProfileCompleted AS IsProfileCompleted,
            @SessionId AS SessionId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

-- -----------------------------------------------------------------------------
-- 5. UPDATE STORED PROCEDURE: PR_CUSTOMER_GET_PROFILE
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_CUSTOMER_GET_PROFILE
    @USER_ID BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        u.USER_ID AS UserId,
        u.DOCTYPE AS DocType,
        u.DOC_NO AS DocNo,
        u.COUNTRY_CODE AS CountryCode,
        u.MOBILE_NUMBER AS MobileNumber,
        u.EMAIL AS Email,
        u.FIRST_NAME AS FirstName,
        u.LAST_NAME AS LastName,
        ISNULL(LTRIM(RTRIM(ISNULL(u.FIRST_NAME, '') + ' ' + ISNULL(u.LAST_NAME, ''))), '') AS FullName,
        u.DOB AS Dob,
        u.GENDER AS Gender,
        u.PROFILE_IMAGE_URL AS ProfileImageUrl,
        u.LANGUAGE_CODE AS LanguageCode,
        u.IS_MOBILE_VERIFIED AS IsMobileVerified,
        u.IS_EMAIL_VERIFIED AS IsEmailVerified,
        u.ELIGIBLE_FOR_ORDER AS EligibleForOrder,
        u.IS_PROFILE_COMPLETED AS IsProfileCompleted,
        u.USER_STATUS AS UserStatus,
        u.CREATED_AT AS CreatedAt,
        u.UPDATED_AT AS UpdatedAt
    FROM dbo.CUSTOMER_USERS u
    WHERE u.USER_ID = @USER_ID;
END;
GO

-- -----------------------------------------------------------------------------
-- 6. UPDATE STORED PROCEDURE: PR_CUSTOMER_UPDATE_PROFILE
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_CUSTOMER_UPDATE_PROFILE
    @USER_ID BIGINT,
    @FIRST_NAME NVARCHAR(100) = NULL,
    @LAST_NAME NVARCHAR(100) = NULL,
    @EMAIL VARCHAR(150) = NULL,
    @DOB DATE = NULL,
    @GENDER VARCHAR(20) = NULL,
    @PROFILE_IMAGE_URL VARCHAR(500) = NULL,
    @LANGUAGE_CODE VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.CUSTOMER_USERS WHERE USER_ID = @USER_ID)
    BEGIN
        RAISERROR('Customer user not found.', 16, 1);
        RETURN;
    END

    -- Clean trimmed inputs
    DECLARE @CleanFirstName NVARCHAR(100) = NULLIF(LTRIM(RTRIM(@FIRST_NAME)), '');
    DECLARE @CleanLastName NVARCHAR(100) = NULLIF(LTRIM(RTRIM(@LAST_NAME)), '');
    DECLARE @CleanEmail VARCHAR(150) = NULLIF(LTRIM(RTRIM(@EMAIL)), '');
    DECLARE @CleanGender VARCHAR(20) = NULLIF(LTRIM(RTRIM(@GENDER)), '');
    DECLARE @CleanProfileImageUrl VARCHAR(500) = NULLIF(LTRIM(RTRIM(@PROFILE_IMAGE_URL)), '');
    DECLARE @CleanLanguageCode VARCHAR(10) = NULLIF(LTRIM(RTRIM(@LANGUAGE_CODE)), '');

    -- Check unique email if provided
    IF @CleanEmail IS NOT NULL
    BEGIN
        IF EXISTS (
            SELECT 1 
            FROM dbo.CUSTOMER_USERS 
            WHERE EMAIL = @CleanEmail 
              AND USER_ID <> @USER_ID
        )
        BEGIN
            RAISERROR('Email address is already registered to another account.', 16, 1);
            RETURN;
        END
    END

    DECLARE @CurrentUtc DATETIME2 = SYSUTCDATETIME();

    -- Determine Effective Values
    DECLARE @EffectiveFirstName NVARCHAR(100);
    DECLARE @EffectiveLastName NVARCHAR(100);
    DECLARE @EffectiveEmail VARCHAR(150);
    DECLARE @EffectiveDob DATE;
    DECLARE @EffectiveGender VARCHAR(20);

    SELECT 
        @EffectiveFirstName = ISNULL(@CleanFirstName, FIRST_NAME),
        @EffectiveLastName = ISNULL(@CleanLastName, LAST_NAME),
        @EffectiveEmail = ISNULL(@CleanEmail, EMAIL),
        @EffectiveDob = ISNULL(@DOB, DOB),
        @EffectiveGender = ISNULL(@CleanGender, GENDER)
    FROM dbo.CUSTOMER_USERS
    WHERE USER_ID = @USER_ID;

    -- Calculate ELIGIBLE_FOR_ORDER & IS_PROFILE_COMPLETED
    DECLARE @EligibleForOrder BIT = 0;
    IF @EffectiveFirstName IS NOT NULL AND @EffectiveLastName IS NOT NULL
    BEGIN
        SET @EligibleForOrder = 1;
    END

    DECLARE @IsProfileCompleted BIT = 0;
    IF @EffectiveFirstName IS NOT NULL 
       AND @EffectiveLastName IS NOT NULL 
       AND @EffectiveEmail IS NOT NULL 
       AND @EffectiveDob IS NOT NULL 
       AND @EffectiveGender IS NOT NULL
    BEGIN
        SET @IsProfileCompleted = 1;
    END

    -- Update Customer User Record
    UPDATE dbo.CUSTOMER_USERS
    SET 
        FIRST_NAME = @EffectiveFirstName,
        LAST_NAME = @EffectiveLastName,
        EMAIL = @EffectiveEmail,
        DOB = @EffectiveDob,
        GENDER = @EffectiveGender,
        PROFILE_IMAGE_URL = ISNULL(@CleanProfileImageUrl, PROFILE_IMAGE_URL),
        LANGUAGE_CODE = ISNULL(@CleanLanguageCode, LANGUAGE_CODE),
        ELIGIBLE_FOR_ORDER = @EligibleForOrder,
        IS_PROFILE_COMPLETED = @IsProfileCompleted,
        UPDATED_AT = @CurrentUtc
    WHERE USER_ID = @USER_ID;

    -- Return updated profile
    EXEC dbo.PR_CUSTOMER_GET_PROFILE @USER_ID = @USER_ID;
END;
GO
