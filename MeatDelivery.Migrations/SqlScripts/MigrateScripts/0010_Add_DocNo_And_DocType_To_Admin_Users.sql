-- =============================================================================
-- Migration: 0010_Add_DocNo_And_DocType_To_Admin_Users.sql
-- Description:
-- 1. Adds DOCTYPE and DOC_NO columns to dbo.ADMIN_USERS
-- 2. Configures 'ADM1' document numbering sequence in dbo.M_DOC_NO
-- 3. Backfills existing admin user accounts with generated DOC_NO
-- 4. Updates Admin stored procedures to return DocType and DocNo
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. ADD DOCTYPE AND DOC_NO COLUMNS TO dbo.ADMIN_USERS
-- -----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID('dbo.ADMIN_USERS') 
      AND name = 'DOCTYPE'
)
BEGIN
    ALTER TABLE dbo.ADMIN_USERS ADD DOCTYPE VARCHAR(20) NULL;
END;
GO

IF NOT EXISTS (
    SELECT 1 
    FROM sys.columns 
    WHERE object_id = OBJECT_ID('dbo.ADMIN_USERS') 
      AND name = 'DOC_NO'
)
BEGIN
    ALTER TABLE dbo.ADMIN_USERS ADD DOC_NO VARCHAR(50) NULL;
END;
GO

IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE object_id = OBJECT_ID('dbo.ADMIN_USERS') 
      AND name = 'UQ_ADMIN_USERS_DOC_NO'
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UQ_ADMIN_USERS_DOC_NO 
    ON dbo.ADMIN_USERS(DOC_NO) 
    WHERE DOC_NO IS NOT NULL;
END;
GO

-- -----------------------------------------------------------------------------
-- 2. SEED 'ADM1' DOCTYPE CONFIGURATION IN dbo.M_DOC_NO
-- -----------------------------------------------------------------------------
DECLARE @DefaultCompanyId BIGINT;
SELECT TOP 1 @DefaultCompanyId = COMPANY_CONFIG_ID FROM dbo.COMPANY_CONFIG WHERE COMPANY_CODE = 'AL_AZIMA';

IF NOT EXISTS (SELECT 1 FROM dbo.M_DOC_NO WHERE DOCTYPE = 'ADM1')
BEGIN
    INSERT INTO dbo.M_DOC_NO (
        MDOC,
        DOCTYPE,
        DESCRIPTION,
        COMPANY_CONFIG_ID,
        PREFIX,
        SUFFIX,
        DIGIT_NO,
        START_DOCNO,
        PERIODWISE_YN,
        PERIOD_TYPE,
        IS_ACTIVE
    )
    VALUES (
        'ADM',
        'ADM1',
        'Admin User Number',
        @DefaultCompanyId,
        'ADM',
        NULL,
        10,
        0,
        'N',
        'NONE',
        1
    );
END;
GO

-- -----------------------------------------------------------------------------
-- 3. BACKFILL EXISTING ADMIN USERS WITH SEQUENTIAL DOC_NO
-- -----------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM dbo.ADMIN_USERS WHERE DOC_NO IS NULL)
BEGIN
    DECLARE @AdminUserId BIGINT;
    DECLARE @AllocatedDocNo VARCHAR(50);

    DECLARE admin_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT ADMIN_USER_ID
    FROM dbo.ADMIN_USERS
    WHERE DOC_NO IS NULL
    ORDER BY ADMIN_USER_ID ASC;

    OPEN admin_cursor;
    FETCH NEXT FROM admin_cursor INTO @AdminUserId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC dbo.PR_GET_NEXT_DOC_NO @DOCTYPE = 'ADM1', @DOC_NO = @AllocatedDocNo OUTPUT;

        UPDATE dbo.ADMIN_USERS
        SET DOCTYPE = 'ADM1',
            DOC_NO = @AllocatedDocNo,
            UPDATED_AT = SYSUTCDATETIME()
        WHERE ADMIN_USER_ID = @AdminUserId;

        FETCH NEXT FROM admin_cursor INTO @AdminUserId;
    END;

    CLOSE admin_cursor;
    DEALLOCATE admin_cursor;
END;
GO

-- -----------------------------------------------------------------------------
-- 4. UPDATE STORED PROCEDURE: dbo.PR_ADMIN_AUTH_GET_BY_EMAIL
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_ADMIN_AUTH_GET_BY_EMAIL
    @EMAIL VARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;

    -- Return Admin User Data
    SELECT 
        u.ADMIN_USER_ID AS AdminUserId,
        u.DOCTYPE AS DocType,
        u.DOC_NO AS DocNo,
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
-- 5. UPDATE STORED PROCEDURE: dbo.PR_ADMIN_AUTH_REFRESH_SESSION
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
            u.DOCTYPE AS DocType,
            u.DOC_NO AS DocNo,
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
-- 6. UPDATE STORED PROCEDURE: dbo.PR_ADMIN_GET_PROFILE
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_ADMIN_GET_PROFILE
    @ADMIN_USER_ID BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    -- Return Admin Profile
    SELECT 
        u.ADMIN_USER_ID AS AdminUserId,
        u.DOCTYPE AS DocType,
        u.DOC_NO AS DocNo,
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
