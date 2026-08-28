-- =============================================================================
-- AL AZEEM MEAT DELIVERY - COMPLETE CLEAN DATABASE SCHEMA & STORED PROCEDURES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. DROP ALL EXISTING FOREIGN KEYS & TABLES DYNAMICALLY
-- -----------------------------------------------------------------------------
DECLARE @dropFksSql NVARCHAR(MAX) = N'';
SELECT @dropFksSql += N'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id)) + '.' + QUOTENAME(OBJECT_NAME(parent_object_id)) + 
                      N' DROP CONSTRAINT ' + QUOTENAME(name) + ';' + CHAR(13)
FROM sys.foreign_keys;

IF @dropFksSql <> N''
    EXEC sp_executesql @dropFksSql;

DECLARE @dropTablesSql NVARCHAR(MAX) = N'';
SELECT @dropTablesSql += N'DROP TABLE ' + QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) + ';' + CHAR(13)
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

IF @dropTablesSql <> N''
    EXEC sp_executesql @dropTablesSql;
GO

-- -----------------------------------------------------------------------------
-- 2. CREATE SCHEMA VERSIONS TABLE (For Migration Tracking)
-- -----------------------------------------------------------------------------
CREATE TABLE dbo.SchemaVersions
(
    ScriptName NVARCHAR(255) NOT NULL PRIMARY KEY,
    AppliedOn DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    ExecutionTimeMs INT NULL,
    AppliedBy NVARCHAR(100) NULL,
    Checksum NVARCHAR(64) NULL
);
GO

-- -----------------------------------------------------------------------------
-- 3. CREATE ROLES TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE dbo.ROLES
(
    ROLE_ID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ROLE_CODE VARCHAR(50) NOT NULL UNIQUE,
    ROLE_NAME VARCHAR(100) NOT NULL,
    DESCRIPTION VARCHAR(500) NULL,
    IS_ACTIVE BIT NOT NULL DEFAULT 1,
    CREATED_AT DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UPDATED_AT DATETIME2 NULL
);
GO

-- -----------------------------------------------------------------------------
-- 4. CREATE USERS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE dbo.USERS
(
    USER_ID BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    COUNTRY_CODE VARCHAR(10) NOT NULL,
    MOBILE_NUMBER VARCHAR(20) NOT NULL,
    EMAIL VARCHAR(150) NULL,
    PASSWORD_HASH VARCHAR(500) NULL,
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
    CONSTRAINT UQ_USERS_MOBILE UNIQUE (COUNTRY_CODE, MOBILE_NUMBER)
);

CREATE UNIQUE NONCLUSTERED INDEX UQ_USERS_EMAIL 
ON dbo.USERS(EMAIL) 
WHERE EMAIL IS NOT NULL;
GO

-------------------------------------------------------------------------------
--5. CREATE USER ROLES TABLE
-------------------------------------------------------------------------------
CREATE TABLE dbo.USER_ROLES
(
    USER_ROLE_ID BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    USER_ID BIGINT NOT NULL,
    ROLE_ID INT NOT NULL,
    IS_ACTIVE BIT NOT NULL DEFAULT 1,
    ASSIGNED_AT DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    ASSIGNED_BY_USER_ID BIGINT NULL,
    UPDATED_AT DATETIME2 NULL,
    CONSTRAINT FK_USER_ROLES_USER FOREIGN KEY (USER_ID) REFERENCES dbo.USERS(USER_ID),
    CONSTRAINT FK_USER_ROLES_ROLE FOREIGN KEY (ROLE_ID) REFERENCES dbo.ROLES(ROLE_ID),
    CONSTRAINT FK_USER_ROLES_ASSIGNED_BY FOREIGN KEY (ASSIGNED_BY_USER_ID) REFERENCES dbo.USERS(USER_ID),
    CONSTRAINT UQ_USER_ROLES UNIQUE (USER_ID, ROLE_ID)
);
GO

-------------------------------------------------------------------------------
--6. CREATE OTP VERIFICATIONS TABLE
-------------------------------------------------------------------------------
CREATE TABLE dbo.OTP_VERIFICATIONS
(
    OTP_ID BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CHALLENGE_ID UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    USER_ID BIGINT NULL,
    COUNTRY_CODE VARCHAR(10) NOT NULL,
    MOBILE_NUMBER VARCHAR(20) NOT NULL,
    OTP_HASH VARCHAR(500) NOT NULL,
    OTP_PURPOSE VARCHAR(30) NOT NULL,
    ATTEMPT_COUNT INT NOT NULL DEFAULT 0,
    RESEND_COUNT INT NOT NULL DEFAULT 0,
    MAX_ATTEMPTS INT NOT NULL DEFAULT 5,
    OTP_STATUS VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    EXPIRES_AT DATETIME2 NOT NULL,
    RATE_LIMIT_WINDOW_START_AT DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    VERIFIED_AT DATETIME2 NULL,
    CREATED_AT DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UPDATED_AT DATETIME2 NULL,
    CONSTRAINT FK_OTP_VERIFICATIONS_USER FOREIGN KEY (USER_ID) REFERENCES dbo.USERS(USER_ID)
);

CREATE UNIQUE NONCLUSTERED INDEX UQ_OTP_VERIFICATIONS_CHALLENGE_ID 
ON dbo.OTP_VERIFICATIONS(CHALLENGE_ID);

CREATE NONCLUSTERED INDEX IX_OTP_VERIFICATIONS_LOOKUP 
ON dbo.OTP_VERIFICATIONS(COUNTRY_CODE, MOBILE_NUMBER, OTP_STATUS);
GO

-- -----------------------------------------------------------------------------
-- 7. CREATE USER SESSIONS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE dbo.USER_SESSIONS
(
    SESSION_ID BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    USER_ID BIGINT NOT NULL,
    REFRESH_TOKEN_HASH VARCHAR(500) NOT NULL,
    DEVICE_ID VARCHAR(200) NULL,
    DEVICE_TYPE VARCHAR(30) NULL,
    IP_ADDRESS VARCHAR(45) NULL,
    IS_ACTIVE BIT NOT NULL DEFAULT 1,
    EXPIRES_AT DATETIME2 NOT NULL,
    LAST_ACTIVITY_AT DATETIME2 NULL,
    CREATED_AT DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UPDATED_AT DATETIME2 NULL,
    CONSTRAINT FK_USER_SESSIONS_USER FOREIGN KEY (USER_ID) REFERENCES dbo.USERS(USER_ID)
);

CREATE NONCLUSTERED INDEX IX_USER_SESSIONS_USER_ACTIVE 
ON dbo.USER_SESSIONS(USER_ID, IS_ACTIVE);

CREATE NONCLUSTERED INDEX IX_USER_SESSIONS_REFRESH_TOKEN 
ON dbo.USER_SESSIONS(REFRESH_TOKEN_HASH, IS_ACTIVE);
GO

-- -----------------------------------------------------------------------------
-- 8. CREATE ACTIVITY LOGS TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE dbo.ACTIVITY_LOGS
(
    LOG_ID BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    USER_ID BIGINT NULL,
    ACTIVITY_TYPE VARCHAR(50) NOT NULL,
    DESCRIPTION NVARCHAR(500) NOT NULL,
    IP_ADDRESS VARCHAR(45) NULL,
    DEVICE_ID VARCHAR(200) NULL,
    DEVICE_TYPE VARCHAR(30) NULL,
    CREATED_AT DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_ACTIVITY_LOGS_USER FOREIGN KEY (USER_ID) REFERENCES dbo.USERS(USER_ID)
);
GO

-- -----------------------------------------------------------------------------
-- 9. SEED ROLES
-- -----------------------------------------------------------------------------
INSERT INTO dbo.ROLES (ROLE_CODE, ROLE_NAME, DESCRIPTION, IS_ACTIVE)
VALUES 
('CUSTOMER', 'Customer', 'Default customer role for mobile ordering', 1),
('ADMIN', 'Administrator', 'Back-office admin with management privileges', 1),
('SUPER_ADMIN', 'Super Administrator', 'Full system access and configurations', 1),
('DRIVER', 'Delivery Driver', 'Delivery driver for order fulfillment', 1),
('BUTCHER', 'Master Butcher', 'Butcher staff for cutting & preparing orders', 1);
GO

-- =============================================================================
-- 10. CREATE ACTIVE STORED PROCEDURES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SP 1: PR_AUTH_CREATE_OTP_VERIFICATION
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[PR_AUTH_CREATE_OTP_VERIFICATION]
	@CountryCode        VARCHAR(10),
	@MobileNumber       VARCHAR(20),
	@OtpHash            VARCHAR(500),
	@OtpPurpose         VARCHAR(30),
	@ExpiresAt          DATETIME2,
	@MaxAttempts        INT              = 5,
	@WindowMinutes      INT              = 5,
	@MaxResendPerWindow INT              = 3,
	@ChallengeId        UNIQUEIDENTIFIER = NULL
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @LAST_CREATED_AT DATETIME2;
	DECLARE @LAST_RESEND_COUNT INT;
	DECLARE @LAST_WINDOW_START_AT DATETIME2;
	DECLARE @LAST_OTP_STATUS VARCHAR(20);

	SELECT TOP 1
		@LAST_CREATED_AT      = CREATED_AT,
		@LAST_RESEND_COUNT    = ISNULL(RESEND_COUNT, 0),
		@LAST_WINDOW_START_AT = RATE_LIMIT_WINDOW_START_AT,
		@LAST_OTP_STATUS      = OTP_STATUS
	FROM dbo.OTP_VERIFICATIONS
	WHERE COUNTRY_CODE  = @CountryCode
	AND   MOBILE_NUMBER = @MobileNumber
	AND   OTP_PURPOSE   = @OtpPurpose
	ORDER BY OTP_ID DESC;

	-- If the last OTP was already VERIFIED, reset cooldown & rate-limit window for the new login attempt
	IF @LAST_OTP_STATUS = 'VERIFIED'
	BEGIN
		SET @LAST_CREATED_AT = NULL;
		SET @LAST_RESEND_COUNT = 0;
		SET @LAST_WINDOW_START_AT = NULL;
	END

	-- 1. Check 60-second resend cooldown
	DECLARE @CooldownSeconds INT = 60;
	IF @LAST_CREATED_AT IS NOT NULL
	BEGIN
		DECLARE @ELAPSED_SECONDS INT = DATEDIFF(SECOND, @LAST_CREATED_AT, SYSUTCDATETIME());
		IF @ELAPSED_SECONDS < @CooldownSeconds
		BEGIN
			DECLARE @COOLDOWN_REMAINING INT = @CooldownSeconds - @ELAPSED_SECONDS;
			IF @COOLDOWN_REMAINING <= 0 SET @COOLDOWN_REMAINING = 1;

			SELECT 
				CAST(0 AS BIT) AS IsSuccess,
				-1 AS StatusCode,
				FORMATMESSAGE('Please wait %d second(s) before requesting a new OTP.', @COOLDOWN_REMAINING) AS Message,
				@COOLDOWN_REMAINING AS Interval,
				CAST(0 AS BIGINT) AS OtpId,
				CAST(0x0 AS UNIQUEIDENTIFIER) AS ChallengeId,
				@LAST_RESEND_COUNT AS ResendCount;
			RETURN;
		END
	END

	-- 2. Check 5-minute rate limit window (max 3 per window)
	DECLARE @NEW_WINDOW_START_AT DATETIME2, @NEW_RESEND_COUNT INT;

	IF @LAST_WINDOW_START_AT IS NOT NULL
	   AND SYSUTCDATETIME() < DATEADD(MINUTE, @WindowMinutes, @LAST_WINDOW_START_AT)
	BEGIN
		IF @LAST_RESEND_COUNT >= @MaxResendPerWindow
		BEGIN
			DECLARE @WINDOW_EXPIRES_AT DATETIME2 = DATEADD(MINUTE, @WindowMinutes, @LAST_WINDOW_START_AT);
			DECLARE @WAIT_SECONDS INT = DATEDIFF(SECOND, SYSUTCDATETIME(), @WINDOW_EXPIRES_AT);
			IF @WAIT_SECONDS <= 0 SET @WAIT_SECONDS = 1;

			SELECT 
				CAST(0 AS BIT) AS IsSuccess,
				-1 AS StatusCode,
				FORMATMESSAGE('OTP resend limit reached (%d/%d). Please try again in %d second(s).', @LAST_RESEND_COUNT, @MaxResendPerWindow, @WAIT_SECONDS) AS Message,
				@WAIT_SECONDS AS Interval,
				CAST(0 AS BIGINT) AS OtpId,
				CAST(0x0 AS UNIQUEIDENTIFIER) AS ChallengeId,
				@LAST_RESEND_COUNT AS ResendCount;
			RETURN;
		END

		SET @NEW_WINDOW_START_AT = @LAST_WINDOW_START_AT;
		SET @NEW_RESEND_COUNT    = @LAST_RESEND_COUNT + 1;
	END
	ELSE
	BEGIN
		SET @NEW_WINDOW_START_AT = SYSUTCDATETIME();
		SET @NEW_RESEND_COUNT    = 1;
	END

	IF @ChallengeId IS NULL SET @ChallengeId = NEWID();

	UPDATE dbo.OTP_VERIFICATIONS
	SET OTP_STATUS = 'INVALIDATED', UPDATED_AT = SYSUTCDATETIME()
	WHERE COUNTRY_CODE  = @CountryCode
	AND   MOBILE_NUMBER = @MobileNumber
	AND   OTP_PURPOSE   = @OtpPurpose
	AND   OTP_STATUS    = 'PENDING';

	INSERT INTO dbo.OTP_VERIFICATIONS
	(CHALLENGE_ID, COUNTRY_CODE, MOBILE_NUMBER, OTP_HASH, OTP_PURPOSE,
	 ATTEMPT_COUNT, RESEND_COUNT, MAX_ATTEMPTS, OTP_STATUS, EXPIRES_AT,
	 RATE_LIMIT_WINDOW_START_AT, CREATED_AT)
	VALUES
	(@ChallengeId, @CountryCode, @MobileNumber, @OtpHash, @OtpPurpose,
	 0, @NEW_RESEND_COUNT, @MaxAttempts, 'PENDING', @ExpiresAt,
	 @NEW_WINDOW_START_AT, SYSUTCDATETIME());

	DECLARE @NEW_OTP_ID BIGINT = SCOPE_IDENTITY();

	SELECT
		CAST(1 AS BIT) AS IsSuccess,
		1 AS StatusCode,
		'OTP sent successfully.' AS Message,
		60 AS Interval,
		@NEW_OTP_ID AS OtpId,
		@ChallengeId AS ChallengeId,
		@NEW_RESEND_COUNT AS ResendCount;
END;
GO

-- -----------------------------------------------------------------------------
-- SP 2: PR_AUTH_VERIFY_OTP_AND_REGISTER_CUSTOMER
-- -----------------------------------------------------------------------------
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
    DECLARE @ResolvedFullName NVARCHAR(150);

    SELECT @UserId = USER_ID, @ResolvedFullName = FULL_NAME 
    FROM dbo.USERS 
    WHERE COUNTRY_CODE = @CountryCode AND MOBILE_NUMBER = @MobileNumber;

    IF @UserId IS NULL
    BEGIN
        SET @IsNewUser = 1;

        INSERT INTO dbo.USERS
        (
            COUNTRY_CODE,
            MOBILE_NUMBER,
            FIRST_NAME,
            LAST_NAME,
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
            NULL,
            NULL,
            ISNULL(@LanguageCode, 'EN'),
            1,
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
        @SessionId AS SessionId,
        u.FIRST_NAME AS FirstName,
        u.LAST_NAME AS LastName,
        ISNULL(LTRIM(RTRIM(ISNULL(u.FIRST_NAME, '') + ' ' + ISNULL(u.LAST_NAME, ''))), '') AS FullName,
        u.LANGUAGE_CODE AS LanguageCode,
        u.IS_PROFILE_COMPLETED AS IsProfileCompleted,
        @IsNewUser AS IsNewUser,
        r.ROLE_CODE AS RoleCode
    FROM dbo.USERS u
    LEFT JOIN dbo.USER_ROLES ur ON u.USER_ID = ur.USER_ID AND ur.IS_ACTIVE = 1
    LEFT JOIN dbo.ROLES r ON ur.ROLE_ID = r.ROLE_ID
    WHERE u.USER_ID = @UserId;
END;
GO

-- -----------------------------------------------------------------------------
-- SP 3: PR_AUTH_REFRESH_TOKEN_SESSION
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_AUTH_REFRESH_TOKEN_SESSION
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
    DECLARE @SessionId BIGINT;

    SELECT TOP 1 
        @SessionId = s.SESSION_ID,
        @UserId = s.USER_ID
    FROM dbo.USER_SESSIONS s
    WHERE s.REFRESH_TOKEN_HASH = @OldRefreshTokenHash
      AND s.IS_ACTIVE = 1
      AND s.EXPIRES_AT > SYSUTCDATETIME();

    IF @SessionId IS NULL
    BEGIN
        RAISERROR('Invalid or expired refresh token session.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;

    UPDATE dbo.USER_SESSIONS
    SET IS_ACTIVE = 0,
        UPDATED_AT = SYSUTCDATETIME()
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

    UPDATE dbo.USERS
    SET LAST_LOGIN_AT = SYSUTCDATETIME(),
        UPDATED_AT = SYSUTCDATETIME()
    WHERE USER_ID = @UserId;

    COMMIT TRANSACTION;

    SELECT 
        u.USER_ID AS UserId,
        u.FULL_NAME AS FullName,
        u.LANGUAGE_CODE AS LanguageCode,
        u.IS_PROFILE_COMPLETED AS IsProfileCompleted,
        CAST(0 AS BIT) AS IsNewUser,
        r.ROLE_CODE AS RoleCode
    FROM dbo.USERS u
    LEFT JOIN dbo.USER_ROLES ur ON u.USER_ID = ur.USER_ID AND ur.IS_ACTIVE = 1
    LEFT JOIN dbo.ROLES r ON ur.ROLE_ID = r.ROLE_ID
    WHERE u.USER_ID = @UserId;
END;
GO

-- -----------------------------------------------------------------------------
-- SP 4: PR_AUTH_LOGOUT_SESSION
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_AUTH_LOGOUT_SESSION
    @RefreshTokenHash VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.USER_SESSIONS
    SET IS_ACTIVE = 0,
        UPDATED_AT = SYSUTCDATETIME()
    WHERE REFRESH_TOKEN_HASH = @RefreshTokenHash
      AND IS_ACTIVE = 1;
END;
GO

-- -----------------------------------------------------------------------------
-- SP 5: PR_AUTH_REVOKE_ALL_SESSIONS
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_AUTH_REVOKE_ALL_SESSIONS
    @UserId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.USER_SESSIONS
    SET IS_ACTIVE = 0,
        UPDATED_AT = SYSUTCDATETIME()
    WHERE USER_ID = @UserId
      AND IS_ACTIVE = 1;
END;
GO

-- -----------------------------------------------------------------------------
-- SP 6: PR_AUTH_CHECK_MOBILE_EXISTS
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_AUTH_CHECK_MOBILE_EXISTS
    @CountryCode VARCHAR(10),
    @MobileNumber VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM dbo.USERS 
        WHERE COUNTRY_CODE = @CountryCode 
          AND MOBILE_NUMBER = @MobileNumber
    )
        SELECT CAST(1 AS BIT) AS UserExists;
    ELSE
        SELECT CAST(0 AS BIT) AS UserExists;
END;
GO

-- -----------------------------------------------------------------------------
-- SP 7: PR_AUTH_GET_ROLE_PERMISSIONS
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_AUTH_GET_ROLE_PERMISSIONS
    @RoleName VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT r.ROLE_CODE AS PermissionCode
    FROM dbo.ROLES r
    WHERE r.ROLE_CODE = @RoleName AND r.IS_ACTIVE = 1;
END;
GO
