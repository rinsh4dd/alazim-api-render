-- =============================================================================
-- Migration: 0004_Add_Customer_Profile_And_Order_Eligibility.sql
-- Description:
-- 1. Adds ELIGIBLE_FOR_ORDER column to dbo.USERS
-- 2. Backfills ELIGIBLE_FOR_ORDER and IS_PROFILE_COMPLETED based on profile completion rules
-- 3. Creates PR_CUSTOMER_GET_PROFILE and PR_CUSTOMER_UPDATE_PROFILE
-- 4. Updates PR_AUTH_VERIFY_OTP_AND_REGISTER_CUSTOMER to return ELIGIBLE_FOR_ORDER
-- =============================================================================

-- 1. ADD ELIGIBLE_FOR_ORDER COLUMN TO dbo.USERS
IF NOT EXISTS (
    SELECT 1 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID('dbo.USERS') 
      AND name = 'ELIGIBLE_FOR_ORDER'
)
BEGIN
    ALTER TABLE dbo.USERS 
    ADD ELIGIBLE_FOR_ORDER BIT NOT NULL CONSTRAINT DF_USERS_ELIGIBLE_FOR_ORDER DEFAULT 0;
END
GO

-- 2. BACKFILL / SYNCHRONIZE ELIGIBLE_FOR_ORDER & IS_PROFILE_COMPLETED FOR EXISTING RECORDS
-- Rule 1: ELIGIBLE_FOR_ORDER = 1 when FIRST_NAME and LAST_NAME are filled (not null/empty).
-- Rule 2: IS_PROFILE_COMPLETED = 1 when ALL profile fields (FIRST_NAME, LAST_NAME, EMAIL, DOB, GENDER) are filled.
UPDATE dbo.USERS
SET 
    ELIGIBLE_FOR_ORDER = CASE 
        WHEN FIRST_NAME IS NOT NULL AND LTRIM(RTRIM(FIRST_NAME)) <> '' 
         AND LAST_NAME IS NOT NULL AND LTRIM(RTRIM(LAST_NAME)) <> '' 
        THEN 1 
        ELSE 0 
    END,
    IS_PROFILE_COMPLETED = CASE 
        WHEN FIRST_NAME IS NOT NULL AND LTRIM(RTRIM(FIRST_NAME)) <> '' 
         AND LAST_NAME IS NOT NULL AND LTRIM(RTRIM(LAST_NAME)) <> '' 
         AND EMAIL IS NOT NULL AND LTRIM(RTRIM(EMAIL)) <> '' 
         AND DOB IS NOT NULL 
         AND GENDER IS NOT NULL AND LTRIM(RTRIM(GENDER)) <> '' 
        THEN 1 
        ELSE 0 
    END;
GO

-- 3. CREATE / ALTER PR_CUSTOMER_GET_PROFILE
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
    FROM dbo.USERS u
    WHERE u.USER_ID = @USER_ID;
END;
GO

-- 4. CREATE / ALTER PR_CUSTOMER_UPDATE_PROFILE
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

    IF NOT EXISTS (SELECT 1 FROM dbo.USERS WHERE USER_ID = @USER_ID)
    BEGIN
        RAISERROR('User not found.', 16, 1);
        RETURN;
    END

    -- Clean trimmed inputs
    DECLARE @CleanFirstName NVARCHAR(100) = NULLIF(LTRIM(RTRIM(@FIRST_NAME)), '');
    DECLARE @CleanLastName NVARCHAR(100) = NULLIF(LTRIM(RTRIM(@LAST_NAME)), '');
    DECLARE @CleanEmail VARCHAR(150) = NULLIF(LTRIM(RTRIM(@EMAIL)), '');
    DECLARE @CleanGender VARCHAR(20) = NULLIF(LTRIM(RTRIM(@GENDER)), '');
    DECLARE @CleanLanguageCode VARCHAR(10) = NULLIF(LTRIM(RTRIM(@LANGUAGE_CODE)), '');
    DECLARE @CleanProfileImageUrl VARCHAR(500) = NULLIF(LTRIM(RTRIM(@PROFILE_IMAGE_URL)), '');

    -- Check if email is already used by another user
    IF @CleanEmail IS NOT NULL
    BEGIN
        IF EXISTS (
            SELECT 1 
            FROM dbo.USERS 
            WHERE EMAIL = @CleanEmail 
              AND USER_ID <> @USER_ID
        )
        BEGIN
            RAISERROR('Email address is already registered to another account.', 16, 1);
            RETURN;
        END
    END

    BEGIN TRANSACTION;

    -- Update user profile fields
    UPDATE dbo.USERS
    SET 
        FIRST_NAME = ISNULL(@CleanFirstName, FIRST_NAME),
        LAST_NAME = ISNULL(@CleanLastName, LAST_NAME),
        EMAIL = ISNULL(@CleanEmail, EMAIL),
        DOB = ISNULL(@DOB, DOB),
        GENDER = ISNULL(@CleanGender, GENDER),
        PROFILE_IMAGE_URL = ISNULL(@CleanProfileImageUrl, PROFILE_IMAGE_URL),
        LANGUAGE_CODE = ISNULL(@CleanLanguageCode, LANGUAGE_CODE),
        UPDATED_AT = SYSUTCDATETIME()
    WHERE USER_ID = @USER_ID;

    -- Recalculate ELIGIBLE_FOR_ORDER and IS_PROFILE_COMPLETED
    UPDATE dbo.USERS
    SET 
        ELIGIBLE_FOR_ORDER = CASE 
            WHEN FIRST_NAME IS NOT NULL AND LTRIM(RTRIM(FIRST_NAME)) <> '' 
             AND LAST_NAME IS NOT NULL AND LTRIM(RTRIM(LAST_NAME)) <> '' 
            THEN 1 
            ELSE 0 
        END,
        IS_PROFILE_COMPLETED = CASE 
            WHEN FIRST_NAME IS NOT NULL AND LTRIM(RTRIM(FIRST_NAME)) <> '' 
             AND LAST_NAME IS NOT NULL AND LTRIM(RTRIM(LAST_NAME)) <> '' 
             AND EMAIL IS NOT NULL AND LTRIM(RTRIM(EMAIL)) <> '' 
             AND DOB IS NOT NULL 
             AND GENDER IS NOT NULL AND LTRIM(RTRIM(GENDER)) <> '' 
            THEN 1 
            ELSE 0 
        END
    WHERE USER_ID = @USER_ID;

    COMMIT TRANSACTION;

    -- Return updated profile
    EXEC dbo.PR_CUSTOMER_GET_PROFILE @USER_ID = @USER_ID;
END;
GO

-- 4b. CREATE / ALTER PR_CUSTOMER_SAVE_PROFILE (ALIAS TO PR_CUSTOMER_UPDATE_PROFILE)
CREATE OR ALTER PROCEDURE dbo.PR_CUSTOMER_SAVE_PROFILE
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

    EXEC dbo.PR_CUSTOMER_UPDATE_PROFILE
        @USER_ID = @USER_ID,
        @FIRST_NAME = @FIRST_NAME,
        @LAST_NAME = @LAST_NAME,
        @EMAIL = @EMAIL,
        @DOB = @DOB,
        @GENDER = @GENDER,
        @PROFILE_IMAGE_URL = @PROFILE_IMAGE_URL,
        @LANGUAGE_CODE = @LANGUAGE_CODE;
END;
GO

-- 5. UPDATE PR_AUTH_VERIFY_OTP_AND_REGISTER_CUSTOMER
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

    IF @OtpId IS NULL
    BEGIN
        RAISERROR('No pending OTP request found.', 16, 1);
        RETURN;
    END

    IF @OtpStatus <> 'PENDING'
    BEGIN
        RAISERROR('OTP is no longer valid.', 16, 1);
        RETURN;
    END

    IF @AttemptCount >= @MaxAttempts
    BEGIN
        UPDATE dbo.OTP_VERIFICATIONS 
        SET OTP_STATUS = 'BLOCKED', UPDATED_AT = SYSUTCDATETIME()
        WHERE OTP_ID = @OtpId;

        RAISERROR('Maximum verification attempts exceeded. Please request a new OTP.', 16, 1);
        RETURN;
    END

    IF SYSUTCDATETIME() > @OtpExpiresAt
    BEGIN
        UPDATE dbo.OTP_VERIFICATIONS 
        SET OTP_STATUS = 'EXPIRED', UPDATED_AT = SYSUTCDATETIME()
        WHERE OTP_ID = @OtpId;

        RAISERROR('OTP has expired. Please request a new OTP.', 16, 1);
        RETURN;
    END

    IF @StoredOtpHash <> @OtpHash
    BEGIN
        UPDATE dbo.OTP_VERIFICATIONS 
        SET ATTEMPT_COUNT = ATTEMPT_COUNT + 1, UPDATED_AT = SYSUTCDATETIME()
        WHERE OTP_ID = @OtpId;

        DECLARE @RemainingAttempts INT = @MaxAttempts - (@AttemptCount + 1);
        DECLARE @ErrorMessage NVARCHAR(200) = FORMATMESSAGE('Invalid OTP code. %d attempts remaining.', @RemainingAttempts);
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END

    SET XACT_ABORT ON;
    BEGIN TRANSACTION;

    UPDATE dbo.OTP_VERIFICATIONS 
    SET OTP_STATUS = 'VERIFIED', 
        VERIFIED_AT = SYSUTCDATETIME(),
        UPDATED_AT = SYSUTCDATETIME()
    WHERE OTP_ID = @OtpId;

    DECLARE @UserId BIGINT;
    DECLARE @CustomerRoleId INT;
    DECLARE @IsNewUser BIT = 0;

    SELECT @UserId = USER_ID 
    FROM dbo.USERS 
    WHERE COUNTRY_CODE = @CountryCode AND MOBILE_NUMBER = @MobileNumber;

    IF @UserId IS NULL
    BEGIN
        SET @IsNewUser = 1;

        -- Allocate Customer Document Number
        DECLARE @CustomerDocNo VARCHAR(50);
        EXEC dbo.PR_GET_NEXT_DOC_NO
            @DOCTYPE = 'CUS1',
            @DOC_NO = @CustomerDocNo OUTPUT;

        INSERT INTO dbo.USERS
        (
            COUNTRY_CODE,
            MOBILE_NUMBER,
            DOCTYPE,
            DOC_NO,
            FIRST_NAME,
            LAST_NAME,
            LANGUAGE_CODE,
            IS_MOBILE_VERIFIED,
            IS_EMAIL_VERIFIED,
            ELIGIBLE_FOR_ORDER,
            IS_PROFILE_COMPLETED,
            USER_STATUS,
            LAST_LOGIN_AT,
            CREATED_AT
        )
        VALUES
        (
            @CountryCode,
            @MobileNumber,
            'CUS1',
            @CustomerDocNo,
            NULL,
            NULL,
            ISNULL(@LanguageCode, 'EN'),
            1,
            0,
            0,
            0,
            'ACTIVE',
            SYSUTCDATETIME(),
            SYSUTCDATETIME()
        );

        SET @UserId = SCOPE_IDENTITY();

        SELECT @CustomerRoleId = ROLE_ID 
        FROM dbo.ROLES 
        WHERE ROLE_CODE = 'CUSTOMER';

        IF @CustomerRoleId IS NOT NULL
        BEGIN
            INSERT INTO dbo.USER_ROLES (USER_ID, ROLE_ID, IS_ACTIVE, ASSIGNED_AT)
            VALUES (@UserId, @CustomerRoleId, 1, SYSUTCDATETIME());
        END
    END
    ELSE
    BEGIN
        UPDATE dbo.USERS
        SET IS_MOBILE_VERIFIED = 1,
            USER_STATUS = 'ACTIVE',
            LAST_LOGIN_AT = SYSUTCDATETIME(),
            UPDATED_AT = SYSUTCDATETIME()
        WHERE USER_ID = @UserId;
    END

    UPDATE dbo.OTP_VERIFICATIONS 
    SET USER_ID = @UserId 
    WHERE OTP_ID = @OtpId;

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
        @RefreshTokenHash,
        @DeviceId,
        @DeviceType,
        @IpAddress,
        1,
        @SessionExpiresAt,
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    );

    SET @SessionId = SCOPE_IDENTITY();

    COMMIT TRANSACTION;

    SELECT 
        u.USER_ID AS UserId,
        u.DOCTYPE AS DocType,
        u.DOC_NO AS DocNo,
        @SessionId AS SessionId,
        u.FIRST_NAME AS FirstName,
        u.LAST_NAME AS LastName,
        ISNULL(LTRIM(RTRIM(ISNULL(u.FIRST_NAME, '') + ' ' + ISNULL(u.LAST_NAME, ''))), '') AS FullName,
        u.LANGUAGE_CODE AS LanguageCode,
        u.ELIGIBLE_FOR_ORDER AS EligibleForOrder,
        u.IS_PROFILE_COMPLETED AS IsProfileCompleted,
        @IsNewUser AS IsNewUser,
        r.ROLE_CODE AS RoleCode
    FROM dbo.USERS u
    LEFT JOIN dbo.USER_ROLES ur ON u.USER_ID = ur.USER_ID AND ur.IS_ACTIVE = 1
    LEFT JOIN dbo.ROLES r ON ur.ROLE_ID = r.ROLE_ID
    WHERE u.USER_ID = @UserId;
END;
GO
