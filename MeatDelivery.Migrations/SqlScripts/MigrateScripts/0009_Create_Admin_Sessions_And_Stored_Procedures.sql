-- =============================================================================
-- Migration: 0009_Create_Admin_Sessions_And_Stored_Procedures.sql
-- Description:
-- 1. Creates dbo.ADMIN_SESSIONS table
-- 2. Creates Stored Procedures for Admin Authentication, Sessions, and Profiles
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. CREATE dbo.ADMIN_SESSIONS TABLE
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.ADMIN_SESSIONS', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ADMIN_SESSIONS
    (
        ADMIN_SESSION_ID   BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        ADMIN_USER_ID      BIGINT               NOT NULL,
        REFRESH_TOKEN_HASH VARCHAR(500)         NOT NULL,
        DEVICE_ID          VARCHAR(200)         NULL,
        IP_ADDRESS         VARCHAR(45)          NULL,
        USER_AGENT         NVARCHAR(500)        NULL,
        IS_ACTIVE          BIT                  NOT NULL DEFAULT 1,
        EXPIRES_AT         DATETIME2            NOT NULL,
        LAST_ACTIVITY_AT   DATETIME2            NULL,
        CREATED_AT         DATETIME2            NOT NULL DEFAULT SYSUTCDATETIME(),
        UPDATED_AT         DATETIME2            NULL,
        CONSTRAINT FK_ADMIN_SESSIONS_ADMIN FOREIGN KEY (ADMIN_USER_ID) REFERENCES dbo.ADMIN_USERS(ADMIN_USER_ID)
    );

    CREATE NONCLUSTERED INDEX IX_ADMIN_SESSIONS_ADMIN_ACTIVE 
    ON dbo.ADMIN_SESSIONS(ADMIN_USER_ID, IS_ACTIVE);

    CREATE NONCLUSTERED INDEX IX_ADMIN_SESSIONS_REFRESH_TOKEN 
    ON dbo.ADMIN_SESSIONS(REFRESH_TOKEN_HASH, IS_ACTIVE);
END;
GO

-- -----------------------------------------------------------------------------
-- 2. STORED PROCEDURE: PR_ADMIN_AUTH_GET_BY_EMAIL
-- Retrieves Admin user data along with assigned roles for authentication
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_ADMIN_AUTH_GET_BY_EMAIL
    @EMAIL VARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;

    -- Return Admin User Data
    SELECT 
        u.ADMIN_USER_ID AS AdminUserId,
        u.EMAIL AS Email,
        u.PASSWORD_HASH AS PasswordHash,
        u.FIRST_NAME AS FirstName,
        u.LAST_NAME AS LastName,
        ISNULL(LTRIM(RTRIM(ISNULL(u.FIRST_NAME, '') + ' ' + ISNULL(u.LAST_NAME, ''))), '') AS FullName,
        u.COUNTRY_CODE AS CountryCode,
        u.MOBILE_NUMBER AS MobileNumber,
        u.PROFILE_IMAGE_URL AS ProfileImageUrl,
        u.ADMIN_STATUS AS AdminStatus,
        u.FAILED_LOGIN_COUNT AS FailedLoginCount,
        u.LOCKED_UNTIL AS LockedUntil,
        u.LAST_LOGIN_AT AS LastLoginAt,
        u.PASSWORD_CHANGED_AT AS PasswordChangedAt,
        u.CREATED_AT AS CreatedAt,
        u.UPDATED_AT AS UpdatedAt
    FROM dbo.ADMIN_USERS u
    WHERE u.EMAIL = @EMAIL;

    -- Return Assigned Roles
    SELECT 
        r.ROLE_CODE AS RoleCode,
        r.ROLE_NAME AS RoleName
    FROM dbo.ADMIN_USERS u
    INNER JOIN dbo.ADMIN_USER_ROLES ur ON ur.ADMIN_USER_ID = u.ADMIN_USER_ID AND ur.IS_ACTIVE = 1
    INNER JOIN dbo.ROLES r ON r.ROLE_ID = ur.ROLE_ID AND r.IS_ACTIVE = 1
    WHERE u.EMAIL = @EMAIL;
END;
GO

-- -----------------------------------------------------------------------------
-- 3. STORED PROCEDURE: PR_ADMIN_AUTH_RECORD_LOGIN_SUCCESS
-- Resets failed attempt counter, updates last login, and upgrades hash if provided
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_ADMIN_AUTH_RECORD_LOGIN_SUCCESS
    @ADMIN_USER_ID BIGINT,
    @UPGRADED_PASSWORD_HASH VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CurrentUtc DATETIME2 = SYSUTCDATETIME();

    UPDATE dbo.ADMIN_USERS
    SET 
        FAILED_LOGIN_COUNT = 0,
        LOCKED_UNTIL = NULL,
        LAST_LOGIN_AT = @CurrentUtc,
        PASSWORD_HASH = ISNULL(@UPGRADED_PASSWORD_HASH, PASSWORD_HASH),
        UPDATED_AT = @CurrentUtc
    WHERE ADMIN_USER_ID = @ADMIN_USER_ID;
END;
GO

-- -----------------------------------------------------------------------------
-- 4. STORED PROCEDURE: PR_ADMIN_AUTH_RECORD_LOGIN_FAILURE
-- Increments failed attempts and locks account if threshold (5) is reached
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_ADMIN_AUTH_RECORD_LOGIN_FAILURE
    @ADMIN_USER_ID BIGINT,
    @MAX_ATTEMPTS INT = 5,
    @LOCKOUT_MINUTES INT = 15
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CurrentUtc DATETIME2 = SYSUTCDATETIME();
    DECLARE @NewFailedCount INT;
    DECLARE @NewLockedUntil DATETIME2 = NULL;

    SELECT @NewFailedCount = ISNULL(FAILED_LOGIN_COUNT, 0) + 1
    FROM dbo.ADMIN_USERS WITH (UPDLOCK, ROWLOCK)
    WHERE ADMIN_USER_ID = @ADMIN_USER_ID;

    IF @NewFailedCount >= @MAX_ATTEMPTS
    BEGIN
        SET @NewLockedUntil = DATEADD(MINUTE, @LOCKOUT_MINUTES, @CurrentUtc);
    END;

    UPDATE dbo.ADMIN_USERS
    SET 
        FAILED_LOGIN_COUNT = @NewFailedCount,
        LOCKED_UNTIL = @NewLockedUntil,
        UPDATED_AT = @CurrentUtc
    WHERE ADMIN_USER_ID = @ADMIN_USER_ID;

    SELECT 
        @NewFailedCount AS FailedLoginCount,
        @NewLockedUntil AS LockedUntil;
END;
GO

-- -----------------------------------------------------------------------------
-- 5. STORED PROCEDURE: PR_ADMIN_AUTH_CREATE_SESSION
-- Inserts a new admin session record
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_ADMIN_AUTH_CREATE_SESSION
    @ADMIN_USER_ID BIGINT,
    @REFRESH_TOKEN_HASH VARCHAR(500),
    @DEVICE_ID VARCHAR(200) = NULL,
    @IP_ADDRESS VARCHAR(45) = NULL,
    @USER_AGENT NVARCHAR(500) = NULL,
    @EXPIRES_AT DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CurrentUtc DATETIME2 = SYSUTCDATETIME();

    INSERT INTO dbo.ADMIN_SESSIONS
    (
        ADMIN_USER_ID,
        REFRESH_TOKEN_HASH,
        DEVICE_ID,
        IP_ADDRESS,
        USER_AGENT,
        IS_ACTIVE,
        EXPIRES_AT,
        LAST_ACTIVITY_AT,
        CREATED_AT
    )
    VALUES
    (
        @ADMIN_USER_ID,
        @REFRESH_TOKEN_HASH,
        @DEVICE_ID,
        @IP_ADDRESS,
        @USER_AGENT,
        1,
        @EXPIRES_AT,
        @CurrentUtc,
        @CurrentUtc
    );

    SELECT SCOPE_IDENTITY() AS AdminSessionId;
END;
GO

-- -----------------------------------------------------------------------------
-- 6. STORED PROCEDURE: PR_ADMIN_AUTH_REFRESH_SESSION
-- Validates current refresh session, revokes it, and registers the new session
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_ADMIN_AUTH_REFRESH_SESSION
    @CURRENT_REFRESH_TOKEN_HASH VARCHAR(500),
    @NEW_REFRESH_TOKEN_HASH VARCHAR(500),
    @DEVICE_ID VARCHAR(200) = NULL,
    @IP_ADDRESS VARCHAR(45) = NULL,
    @USER_AGENT NVARCHAR(500) = NULL,
    @NEW_EXPIRES_AT DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CurrentUtc DATETIME2 = SYSUTCDATETIME();
        DECLARE @SessionId BIGINT;
        DECLARE @AdminUserId BIGINT;
        DECLARE @IsActive BIT;
        DECLARE @ExpiresAt DATETIME2;
        DECLARE @AdminStatus VARCHAR(20);

        SELECT 
            @SessionId = s.ADMIN_SESSION_ID,
            @AdminUserId = s.ADMIN_USER_ID,
            @IsActive = s.IS_ACTIVE,
            @ExpiresAt = s.EXPIRES_AT,
            @AdminStatus = u.ADMIN_STATUS
        FROM dbo.ADMIN_SESSIONS s WITH (UPDLOCK, ROWLOCK)
        INNER JOIN dbo.ADMIN_USERS u ON u.ADMIN_USER_ID = s.ADMIN_USER_ID
        WHERE s.REFRESH_TOKEN_HASH = @CURRENT_REFRESH_TOKEN_HASH;

        IF @SessionId IS NULL OR @IsActive = 0
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR('Invalid or inactive admin session.', 16, 1);
            RETURN;
        END;

        IF @CurrentUtc > @ExpiresAt
        BEGIN
            UPDATE dbo.ADMIN_SESSIONS
            SET IS_ACTIVE = 0, UPDATED_AT = @CurrentUtc
            WHERE ADMIN_SESSION_ID = @SessionId;

            ROLLBACK TRANSACTION;
            RAISERROR('Admin session has expired. Please log in again.', 16, 1);
            RETURN;
        END;

        IF @AdminStatus <> 'ACTIVE'
        BEGIN
            UPDATE dbo.ADMIN_SESSIONS
            SET IS_ACTIVE = 0, UPDATED_AT = @CurrentUtc
            WHERE ADMIN_USER_ID = @AdminUserId;

            ROLLBACK TRANSACTION;
            RAISERROR('Admin account is inactive or locked.', 16, 1);
            RETURN;
        END;

        -- Revoke old session
        UPDATE dbo.ADMIN_SESSIONS
        SET IS_ACTIVE = 0, UPDATED_AT = @CurrentUtc
        WHERE ADMIN_SESSION_ID = @SessionId;

        -- Create new session
        DECLARE @NewSessionId BIGINT;
        INSERT INTO dbo.ADMIN_SESSIONS
        (
            ADMIN_USER_ID,
            REFRESH_TOKEN_HASH,
            DEVICE_ID,
            IP_ADDRESS,
            USER_AGENT,
            IS_ACTIVE,
            EXPIRES_AT,
            LAST_ACTIVITY_AT,
            CREATED_AT
        )
        VALUES
        (
            @AdminUserId,
            @NEW_REFRESH_TOKEN_HASH,
            @DEVICE_ID,
            @IP_ADDRESS,
            @USER_AGENT,
            1,
            @NEW_EXPIRES_AT,
            @CurrentUtc,
            @CurrentUtc
        );
        SET @NewSessionId = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        -- Return Admin Data
        SELECT 
            u.ADMIN_USER_ID AS AdminUserId,
            u.EMAIL AS Email,
            u.FIRST_NAME AS FirstName,
            u.LAST_NAME AS LastName,
            ISNULL(LTRIM(RTRIM(ISNULL(u.FIRST_NAME, '') + ' ' + ISNULL(u.LAST_NAME, ''))), '') AS FullName,
            @NewSessionId AS NewSessionId
        FROM dbo.ADMIN_USERS u
        WHERE u.ADMIN_USER_ID = @AdminUserId;

        -- Return Roles
        SELECT 
            r.ROLE_CODE AS RoleCode,
            r.ROLE_NAME AS RoleName
        FROM dbo.ADMIN_USER_ROLES ur
        INNER JOIN dbo.ROLES r ON r.ROLE_ID = ur.ROLE_ID AND r.IS_ACTIVE = 1
        WHERE ur.ADMIN_USER_ID = @AdminUserId AND ur.IS_ACTIVE = 1;

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
-- 7. STORED PROCEDURE: PR_ADMIN_AUTH_LOGOUT_SESSION
-- Revokes a single admin refresh session
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_ADMIN_AUTH_LOGOUT_SESSION
    @REFRESH_TOKEN_HASH VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.ADMIN_SESSIONS
    SET IS_ACTIVE = 0,
        UPDATED_AT = SYSUTCDATETIME()
    WHERE REFRESH_TOKEN_HASH = @REFRESH_TOKEN_HASH;
END;
GO

-- -----------------------------------------------------------------------------
-- 8. STORED PROCEDURE: PR_ADMIN_GET_PROFILE
-- Retrieves full profile details and assigned roles of an admin user
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_ADMIN_GET_PROFILE
    @ADMIN_USER_ID BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    -- Return Admin Profile
    SELECT 
        u.ADMIN_USER_ID AS AdminUserId,
        u.EMAIL AS Email,
        u.FIRST_NAME AS FirstName,
        u.LAST_NAME AS LastName,
        ISNULL(LTRIM(RTRIM(ISNULL(u.FIRST_NAME, '') + ' ' + ISNULL(u.LAST_NAME, ''))), '') AS FullName,
        u.COUNTRY_CODE AS CountryCode,
        u.MOBILE_NUMBER AS MobileNumber,
        u.PROFILE_IMAGE_URL AS ProfileImageUrl,
        u.ADMIN_STATUS AS AdminStatus,
        u.LAST_LOGIN_AT AS LastLoginAt,
        u.CREATED_AT AS CreatedAt,
        u.UPDATED_AT AS UpdatedAt
    FROM dbo.ADMIN_USERS u
    WHERE u.ADMIN_USER_ID = @ADMIN_USER_ID;

    -- Return Roles
    SELECT 
        r.ROLE_CODE AS RoleCode,
        r.ROLE_NAME AS RoleName,
        r.DESCRIPTION AS Description
    FROM dbo.ADMIN_USER_ROLES ur
    INNER JOIN dbo.ROLES r ON r.ROLE_ID = ur.ROLE_ID AND r.IS_ACTIVE = 1
    WHERE ur.ADMIN_USER_ID = @ADMIN_USER_ID AND ur.IS_ACTIVE = 1;
END;
GO
