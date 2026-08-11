-- Migration 0037: Create PR_AUTH Stored Procedures matching repository calls

-- 1. PR_AUTH_CREATE_OTP_VERIFICATION
CREATE OR ALTER PROCEDURE dbo.PR_AUTH_CREATE_OTP_VERIFICATION
    @CountryCode VARCHAR(10),
    @MobileNumber VARCHAR(20),
    @OtpHash VARCHAR(500),
    @OtpPurpose VARCHAR(30),
    @ExpiresAt DATETIME2,
    @MaxAttempts INT = 5
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.OTP_VERIFICATIONS
    SET OTP_STATUS = 'INVALIDATED',
        UPDATED_AT = SYSUTCDATETIME()
    WHERE COUNTRY_CODE = @CountryCode 
      AND MOBILE_NUMBER = @MobileNumber 
      AND OTP_PURPOSE = @OtpPurpose 
      AND OTP_STATUS = 'PENDING';

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

-- 2. PR_AUTH_REGISTER_CUSTOMER_AND_SESSION
CREATE OR ALTER PROCEDURE dbo.PR_AUTH_REGISTER_CUSTOMER_AND_SESSION
    @CountryCode VARCHAR(10),
    @MobileNumber VARCHAR(20),
    @FullName NVARCHAR(150) = NULL,
    @LanguageCode VARCHAR(10) = 'EN',
    @RefreshTokenHash VARCHAR(500),
    @DeviceId VARCHAR(200) = NULL,
    @DeviceType VARCHAR(30) = NULL,
    @IpAddress VARCHAR(45) = NULL,
    @ExpiresAt DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DECLARE @UserId BIGINT;
    DECLARE @CustomerRoleId INT;
    DECLARE @IsNewUser BIT = 0;
    DECLARE @ResolvedFullName NVARCHAR(150);

    SELECT @UserId = USER_ID, @ResolvedFullName = FULL_NAME 
    FROM dbo.USERS 
    WHERE COUNTRY_CODE = @CountryCode AND MOBILE_NUMBER = @MobileNumber;

    IF @UserId IS NULL
    BEGIN
        SET @IsNewUser = 1;
        SET @ResolvedFullName = ISNULL(@FullName, N'Customer');

        INSERT INTO dbo.USERS
        (
            COUNTRY_CODE,
            MOBILE_NUMBER,
            FULL_NAME,
            LANGUAGE_CODE,
            IS_MOBILE_VERIFIED,
            USER_STATUS,
            LAST_LOGIN_AT,
            CREATED_AT
        )
        VALUES
        (
            @CountryCode,
            @MobileNumber,
            @ResolvedFullName,
            ISNULL(@LanguageCode, 'EN'),
            1,
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
        SET LAST_LOGIN_AT = SYSUTCDATETIME(),
            UPDATED_AT = SYSUTCDATETIME()
        WHERE USER_ID = @UserId;
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
        @ExpiresAt,
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    );

    DECLARE @SessionId BIGINT = SCOPE_IDENTITY();

    COMMIT TRANSACTION;

    SELECT 
        @UserId AS UserId,
        @ResolvedFullName AS FullName,
        @CountryCode AS CountryCode,
        @MobileNumber AS MobileNumber,
        @IsNewUser AS IsNewUser,
        @SessionId AS SessionId;
END;
GO

-- 3. PR_AUTH_VERIFY_OTP_AND_REGISTER_CUSTOMER
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
    SET XACT_ABORT ON;

    DECLARE @OtpId BIGINT;
    DECLARE @DbOtpHash VARCHAR(500);
    DECLARE @ExpiresAt DATETIME2;
    DECLARE @AttemptCount INT;
    DECLARE @OtpStatus VARCHAR(20);

    SELECT TOP 1 
        @OtpId = OTP_ID,
        @DbOtpHash = OTP_HASH,
        @ExpiresAt = EXPIRES_AT,
        @AttemptCount = ATTEMPT_COUNT,
        @OtpStatus = OTP_STATUS
    FROM dbo.OTP_VERIFICATIONS
    WHERE COUNTRY_CODE = @CountryCode 
      AND MOBILE_NUMBER = @MobileNumber
      AND OTP_STATUS = 'PENDING'
    ORDER BY CREATED_AT DESC;

    IF @OtpId IS NULL OR @ExpiresAt < SYSUTCDATETIME()
    BEGIN
        RAISERROR('Invalid or expired OTP request. Please request a new OTP.', 16, 1);
        RETURN;
    END

    IF @AttemptCount >= @MaxAttempts
    BEGIN
        UPDATE dbo.OTP_VERIFICATIONS SET OTP_STATUS = 'BLOCKED', UPDATED_AT = SYSUTCDATETIME() WHERE OTP_ID = @OtpId;
        RAISERROR('Maximum OTP verification attempts exceeded.', 16, 1);
        RETURN;
    END

    IF @DbOtpHash <> @OtpHash
    BEGIN
        UPDATE dbo.OTP_VERIFICATIONS SET ATTEMPT_COUNT = ATTEMPT_COUNT + 1, UPDATED_AT = SYSUTCDATETIME() WHERE OTP_ID = @OtpId;
        RAISERROR('Invalid OTP code provided.', 16, 1);
        RETURN;
    END

    UPDATE dbo.OTP_VERIFICATIONS SET OTP_STATUS = 'VERIFIED', VERIFIED_AT = SYSUTCDATETIME(), UPDATED_AT = SYSUTCDATETIME() WHERE OTP_ID = @OtpId;

    EXEC dbo.PR_AUTH_REGISTER_CUSTOMER_AND_SESSION
        @CountryCode = @CountryCode,
        @MobileNumber = @MobileNumber,
        @FullName = @FullName,
        @LanguageCode = @LanguageCode,
        @RefreshTokenHash = @RefreshTokenHash,
        @DeviceId = @DeviceId,
        @DeviceType = @DeviceType,
        @IpAddress = @IpAddress,
        @ExpiresAt = @SessionExpiresAt;
END;
GO

-- 4. PR_AUTH_REFRESH_TOKEN_SESSION
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
    SET XACT_ABORT ON;

    DECLARE @UserId BIGINT;
    DECLARE @FullName NVARCHAR(150);
    DECLARE @SessionId BIGINT;

    SELECT @UserId = u.USER_ID, @FullName = u.FULL_NAME, @SessionId = s.SESSION_ID
    FROM dbo.USERS u
    INNER JOIN dbo.USER_SESSIONS s ON u.USER_ID = s.USER_ID
    WHERE u.COUNTRY_CODE = @CountryCode 
      AND u.MOBILE_NUMBER = @MobileNumber
      AND s.REFRESH_TOKEN_HASH = @OldRefreshTokenHash
      AND s.IS_ACTIVE = 1
      AND s.EXPIRES_AT > SYSUTCDATETIME();

    IF @UserId IS NULL
    BEGIN
        RAISERROR('Invalid or expired refresh token session.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;

    UPDATE dbo.USER_SESSIONS 
    SET IS_ACTIVE = 0, UPDATED_AT = SYSUTCDATETIME() 
    WHERE SESSION_ID = @SessionId;

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
        @NewRefreshTokenHash,
        @DeviceId,
        @DeviceType,
        @IpAddress,
        1,
        @SessionExpiresAt,
        SYSUTCDATETIME(),
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
END;
GO

-- 5. PR_AUTH_LOGOUT_SESSION
CREATE OR ALTER PROCEDURE dbo.PR_AUTH_LOGOUT_SESSION
    @CountryCode VARCHAR(10),
    @MobileNumber VARCHAR(20),
    @RefreshTokenHash VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE s
    SET s.IS_ACTIVE = 0,
        s.UPDATED_AT = SYSUTCDATETIME()
    FROM dbo.USER_SESSIONS s
    INNER JOIN dbo.USERS u ON s.USER_ID = u.USER_ID
    WHERE u.COUNTRY_CODE = @CountryCode 
      AND u.MOBILE_NUMBER = @MobileNumber
      AND s.REFRESH_TOKEN_HASH = @RefreshTokenHash
      AND s.IS_ACTIVE = 1;
END;
GO

-- 6. PR_AUTH_REVOKE_ALL_SESSIONS
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
