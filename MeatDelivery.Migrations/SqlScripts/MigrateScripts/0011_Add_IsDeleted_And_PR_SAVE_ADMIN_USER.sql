-- =============================================================================
-- MIGRATION SCRIPT: 0011_Add_IsDeleted_And_PR_SAVE_ADMIN_USER.sql
-- Description:
--   1. Adds IS_DELETED (BIT) and DELETED_AT (DATETIME2) columns to dbo.ADMIN_USERS.
--   2. Creates dbo.PR_SAVE_ADMIN_USER (CUD procedure supporting ADD, EDIT, DELETE).
--   3. Creates dbo.PR_GET_ADMIN_USERS (Paginated, filterable admin list).
--   4. Creates dbo.PR_GET_ADMIN_USER_BY_ID.
--   5. Creates dbo.PR_GET_ADMIN_ROLES.
-- =============================================================================

SET NOCOUNT ON;
GO

-- -----------------------------------------------------------------------------
-- 1. ADD IS_DELETED AND DELETED_AT TO ADMIN_USERS
-- -----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.columns 
    WHERE object_id = OBJECT_ID('dbo.ADMIN_USERS') AND name = 'IS_DELETED'
)
BEGIN
    ALTER TABLE dbo.ADMIN_USERS
    ADD IS_DELETED BIT NOT NULL CONSTRAINT DF_ADMIN_USERS_IS_DELETED DEFAULT 0;
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns 
    WHERE object_id = OBJECT_ID('dbo.ADMIN_USERS') AND name = 'DELETED_AT'
)
BEGIN
    ALTER TABLE dbo.ADMIN_USERS
    ADD DELETED_AT DATETIME2 NULL;
END;
GO

-- -----------------------------------------------------------------------------
-- 2. STORED PROCEDURE: dbo.PR_SAVE_ADMIN_USER
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_SAVE_ADMIN_USER
    @MODE                   VARCHAR(10),        -- 'ADD', 'EDIT', 'DELETE'
    @ADMIN_USER_ID          BIGINT = NULL,
    @EMAIL                  VARCHAR(150) = NULL,
    @PASSWORD_HASH          VARCHAR(500) = NULL,
    @FIRST_NAME             NVARCHAR(100) = NULL,
    @LAST_NAME              NVARCHAR(100) = NULL,
    @COUNTRY_CODE           VARCHAR(10) = NULL,
    @MOBILE_NUMBER          VARCHAR(20) = NULL,
    @PROFILE_IMAGE_URL      VARCHAR(500) = NULL,
    @ADMIN_STATUS           VARCHAR(20) = 'ACTIVE',
    @ROLES_CSV              VARCHAR(MAX) = NULL, -- Comma-separated roles e.g. 'STORE_MANAGER,ORDER_MANAGER'
    @ACTIONED_BY_ADMIN_ID   BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @OP_MODE VARCHAR(10) = UPPER(LTRIM(RTRIM(@MODE)));
    DECLARE @NEW_DOC_NO VARCHAR(50);
    DECLARE @DOC_TYPE VARCHAR(20) = 'ADM1';

    -- =========================================================================
    -- MODE: ADD
    -- =========================================================================
    IF @OP_MODE = 'ADD'
    BEGIN
        IF @EMAIL IS NULL OR LTRIM(RTRIM(@EMAIL)) = ''
        BEGIN
            THROW 50001, 'Email is required for new admin user.', 1;
        END;

        SET @EMAIL = LOWER(LTRIM(RTRIM(@EMAIL)));

        -- Check duplicate email among active (non-deleted) accounts
        IF EXISTS (SELECT 1 FROM dbo.ADMIN_USERS WHERE EMAIL = @EMAIL AND IS_DELETED = 0)
        BEGIN
            THROW 50002, 'An active admin user with this email already exists.', 1;
        END;

        -- Allocate next DOC_NO
        EXEC dbo.PR_GET_NEXT_DOC_NO 
            @DOC_TYPE = @DOC_TYPE,
            @DOC_NO = @NEW_DOC_NO OUTPUT;

        BEGIN TRANSACTION;

        INSERT INTO dbo.ADMIN_USERS
        (
            DOCTYPE,
            DOC_NO,
            EMAIL,
            PASSWORD_HASH,
            FIRST_NAME,
            LAST_NAME,
            COUNTRY_CODE,
            MOBILE_NUMBER,
            PROFILE_IMAGE_URL,
            ADMIN_STATUS,
            IS_DELETED,
            CREATED_BY_ADMIN_USER_ID,
            CREATED_AT
        )
        VALUES
        (
            @DOC_TYPE,
            @NEW_DOC_NO,
            @EMAIL,
            @PASSWORD_HASH,
            @FIRST_NAME,
            @LAST_NAME,
            @COUNTRY_CODE,
            @MOBILE_NUMBER,
            @PROFILE_IMAGE_URL,
            ISNULL(@ADMIN_STATUS, 'ACTIVE'),
            0,
            @ACTIONED_BY_ADMIN_ID,
            SYSUTCDATETIME()
        );

        SET @ADMIN_USER_ID = SCOPE_IDENTITY();

        -- Assign Roles
        IF @ROLES_CSV IS NOT NULL AND LTRIM(RTRIM(@ROLES_CSV)) <> ''
        BEGIN
            INSERT INTO dbo.ADMIN_USER_ROLES (ADMIN_USER_ID, ROLE_ID, ASSIGNED_BY_ADMIN_USER_ID, ASSIGNED_AT)
            SELECT 
                @ADMIN_USER_ID,
                r.ROLE_ID,
                @ACTIONED_BY_ADMIN_ID,
                SYSUTCDATETIME()
            FROM string_split(@ROLES_CSV, ',') s
            INNER JOIN dbo.ADMIN_ROLES r ON UPPER(LTRIM(RTRIM(s.value))) = r.ROLE_CODE
            WHERE r.IS_ACTIVE = 1;
        END;

        COMMIT TRANSACTION;

        -- Return the created user
        SELECT 
            u.ADMIN_USER_ID,
            u.DOCTYPE,
            u.DOC_NO,
            u.EMAIL,
            u.FIRST_NAME,
            u.LAST_NAME,
            u.COUNTRY_CODE,
            u.MOBILE_NUMBER,
            u.PROFILE_IMAGE_URL,
            u.ADMIN_STATUS,
            u.IS_DELETED,
            u.DELETED_AT,
            u.CREATED_AT,
            u.UPDATED_AT,
            ISNULL((
                SELECT STRING_AGG(r.ROLE_CODE, ',')
                FROM dbo.ADMIN_USER_ROLES ur
                INNER JOIN dbo.ADMIN_ROLES r ON ur.ROLE_ID = r.ROLE_ID
                WHERE ur.ADMIN_USER_ID = u.ADMIN_USER_ID
            ), '') AS ROLES_CSV
        FROM dbo.ADMIN_USERS u
        WHERE u.ADMIN_USER_ID = @ADMIN_USER_ID;

        RETURN;
    END;

    -- =========================================================================
    -- MODE: EDIT
    -- =========================================================================
    IF @OP_MODE = 'EDIT'
    BEGIN
        IF @ADMIN_USER_ID IS NULL OR @ADMIN_USER_ID <= 0
        BEGIN
            THROW 50003, 'AdminUserId is required for editing.', 1;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.ADMIN_USERS WHERE ADMIN_USER_ID = @ADMIN_USER_ID)
        BEGIN
            THROW 50004, 'Admin user not found.', 1;
        END;

        -- If email changed, check uniqueness
        IF @EMAIL IS NOT NULL AND LTRIM(RTRIM(@EMAIL)) <> ''
        BEGIN
            SET @EMAIL = LOWER(LTRIM(RTRIM(@EMAIL)));
            IF EXISTS (SELECT 1 FROM dbo.ADMIN_USERS WHERE EMAIL = @EMAIL AND ADMIN_USER_ID <> @ADMIN_USER_ID AND IS_DELETED = 0)
            BEGIN
                THROW 50005, 'Another active admin user already uses this email address.', 1;
            END;
        END;

        BEGIN TRANSACTION;

        UPDATE dbo.ADMIN_USERS
        SET 
            EMAIL = ISNULL(@EMAIL, EMAIL),
            PASSWORD_HASH = CASE WHEN @PASSWORD_HASH IS NOT NULL AND LTRIM(RTRIM(@PASSWORD_HASH)) <> '' THEN @PASSWORD_HASH ELSE PASSWORD_HASH END,
            PASSWORD_CHANGED_AT = CASE WHEN @PASSWORD_HASH IS NOT NULL AND LTRIM(RTRIM(@PASSWORD_HASH)) <> '' THEN SYSUTCDATETIME() ELSE PASSWORD_CHANGED_AT END,
            FIRST_NAME = ISNULL(@FIRST_NAME, FIRST_NAME),
            LAST_NAME = ISNULL(@LAST_NAME, LAST_NAME),
            COUNTRY_CODE = ISNULL(@COUNTRY_CODE, COUNTRY_CODE),
            MOBILE_NUMBER = ISNULL(@MOBILE_NUMBER, MOBILE_NUMBER),
            PROFILE_IMAGE_URL = ISNULL(@PROFILE_IMAGE_URL, PROFILE_IMAGE_URL),
            ADMIN_STATUS = ISNULL(@ADMIN_STATUS, ADMIN_STATUS),
            UPDATED_AT = SYSUTCDATETIME()
        WHERE ADMIN_USER_ID = @ADMIN_USER_ID;

        -- Update Roles if specified
        IF @ROLES_CSV IS NOT NULL
        BEGIN
            DELETE FROM dbo.ADMIN_USER_ROLES WHERE ADMIN_USER_ID = @ADMIN_USER_ID;

            IF LTRIM(RTRIM(@ROLES_CSV)) <> ''
            BEGIN
                INSERT INTO dbo.ADMIN_USER_ROLES (ADMIN_USER_ID, ROLE_ID, ASSIGNED_BY_ADMIN_USER_ID, ASSIGNED_AT)
                SELECT 
                    @ADMIN_USER_ID,
                    r.ROLE_ID,
                    @ACTIONED_BY_ADMIN_ID,
                    SYSUTCDATETIME()
                FROM string_split(@ROLES_CSV, ',') s
                INNER JOIN dbo.ADMIN_ROLES r ON UPPER(LTRIM(RTRIM(s.value))) = r.ROLE_CODE
                WHERE r.IS_ACTIVE = 1;
            END;
        END;

        COMMIT TRANSACTION;

        -- Return the updated user
        SELECT 
            u.ADMIN_USER_ID,
            u.DOCTYPE,
            u.DOC_NO,
            u.EMAIL,
            u.FIRST_NAME,
            u.LAST_NAME,
            u.COUNTRY_CODE,
            u.MOBILE_NUMBER,
            u.PROFILE_IMAGE_URL,
            u.ADMIN_STATUS,
            u.IS_DELETED,
            u.DELETED_AT,
            u.CREATED_AT,
            u.UPDATED_AT,
            ISNULL((
                SELECT STRING_AGG(r.ROLE_CODE, ',')
                FROM dbo.ADMIN_USER_ROLES ur
                INNER JOIN dbo.ADMIN_ROLES r ON ur.ROLE_ID = r.ROLE_ID
                WHERE ur.ADMIN_USER_ID = u.ADMIN_USER_ID
            ), '') AS ROLES_CSV
        FROM dbo.ADMIN_USERS u
        WHERE u.ADMIN_USER_ID = @ADMIN_USER_ID;

        RETURN;
    END;

    -- =========================================================================
    -- MODE: DELETE
    -- =========================================================================
    IF @OP_MODE = 'DELETE'
    BEGIN
        IF @ADMIN_USER_ID IS NULL OR @ADMIN_USER_ID <= 0
        BEGIN
            THROW 50006, 'AdminUserId is required for deletion.', 1;
        END;

        -- Prevent self-deletion
        IF @ACTIONED_BY_ADMIN_ID IS NOT NULL AND @ADMIN_USER_ID = @ACTIONED_BY_ADMIN_ID
        BEGIN
            THROW 50007, 'Super Admin cannot delete their own active account.', 1;
        END;

        UPDATE dbo.ADMIN_USERS
        SET 
            IS_DELETED = 1,
            DELETED_AT = SYSUTCDATETIME(),
            ADMIN_STATUS = 'SUSPENDED',
            UPDATED_AT = SYSUTCDATETIME()
        WHERE ADMIN_USER_ID = @ADMIN_USER_ID;

        SELECT 
            u.ADMIN_USER_ID,
            u.DOCTYPE,
            u.DOC_NO,
            u.EMAIL,
            u.FIRST_NAME,
            u.LAST_NAME,
            u.COUNTRY_CODE,
            u.MOBILE_NUMBER,
            u.PROFILE_IMAGE_URL,
            u.ADMIN_STATUS,
            u.IS_DELETED,
            u.DELETED_AT,
            u.CREATED_AT,
            u.UPDATED_AT,
            ISNULL((
                SELECT STRING_AGG(r.ROLE_CODE, ',')
                FROM dbo.ADMIN_USER_ROLES ur
                INNER JOIN dbo.ADMIN_ROLES r ON ur.ROLE_ID = r.ROLE_ID
                WHERE ur.ADMIN_USER_ID = u.ADMIN_USER_ID
            ), '') AS ROLES_CSV
        FROM dbo.ADMIN_USERS u
        WHERE u.ADMIN_USER_ID = @ADMIN_USER_ID;

        RETURN;
    END;

    THROW 50008, 'Invalid operation mode. Expected ADD, EDIT, or DELETE.', 1;
END;
GO

-- -----------------------------------------------------------------------------
-- 3. STORED PROCEDURE: dbo.PR_GET_ADMIN_USERS
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_GET_ADMIN_USERS
    @SEARCH             NVARCHAR(100) = NULL,
    @ROLE_CODE          VARCHAR(50) = NULL,
    @ADMIN_STATUS       VARCHAR(20) = NULL,
    @INCLUDE_DELETED    BIT = 0,
    @PAGE_NUMBER        INT = 1,
    @PAGE_SIZE          INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    IF @PAGE_NUMBER < 1 SET @PAGE_NUMBER = 1;
    IF @PAGE_SIZE < 1 SET @PAGE_SIZE = 20;
    IF @PAGE_SIZE > 100 SET @PAGE_SIZE = 100;

    DECLARE @OFFSET INT = (@PAGE_NUMBER - 1) * @PAGE_SIZE;

    ;WITH FilteredUsers AS
    (
        SELECT 
            u.ADMIN_USER_ID,
            u.DOCTYPE,
            u.DOC_NO,
            u.EMAIL,
            u.FIRST_NAME,
            u.LAST_NAME,
            u.COUNTRY_CODE,
            u.MOBILE_NUMBER,
            u.PROFILE_IMAGE_URL,
            u.ADMIN_STATUS,
            u.IS_DELETED,
            u.DELETED_AT,
            u.LAST_LOGIN_AT,
            u.CREATED_AT,
            u.UPDATED_AT,
            ISNULL((
                SELECT STRING_AGG(r.ROLE_CODE, ',')
                FROM dbo.ADMIN_USER_ROLES ur
                INNER JOIN dbo.ADMIN_ROLES r ON ur.ROLE_ID = r.ROLE_ID
                WHERE ur.ADMIN_USER_ID = u.ADMIN_USER_ID
            ), '') AS ROLES_CSV
        FROM dbo.ADMIN_USERS u
        WHERE (@INCLUDE_DELETED = 1 OR u.IS_DELETED = 0)
          AND (@ADMIN_STATUS IS NULL OR u.ADMIN_STATUS = @ADMIN_STATUS)
          AND (
              @SEARCH IS NULL OR LTRIM(RTRIM(@SEARCH)) = ''
              OR u.FIRST_NAME LIKE '%' + @SEARCH + '%'
              OR u.LAST_NAME LIKE '%' + @SEARCH + '%'
              OR u.EMAIL LIKE '%' + @SEARCH + '%'
              OR u.DOC_NO LIKE '%' + @SEARCH + '%'
              OR u.MOBILE_NUMBER LIKE '%' + @SEARCH + '%'
          )
          AND (
              @ROLE_CODE IS NULL OR LTRIM(RTRIM(@ROLE_CODE)) = ''
              OR EXISTS (
                  SELECT 1 
                  FROM dbo.ADMIN_USER_ROLES ur2
                  INNER JOIN dbo.ADMIN_ROLES r2 ON ur2.ROLE_ID = r2.ROLE_ID
                  WHERE ur2.ADMIN_USER_ID = u.ADMIN_USER_ID
                    AND r2.ROLE_CODE = UPPER(LTRIM(RTRIM(@ROLE_CODE)))
              )
          )
    )
    SELECT 
        *,
        COUNT(*) OVER() AS TOTAL_COUNT
    FROM FilteredUsers
    ORDER BY ADMIN_USER_ID DESC
    OFFSET @OFFSET ROWS
    FETCH NEXT @PAGE_SIZE ROWS ONLY;
END;
GO

-- -----------------------------------------------------------------------------
-- 4. STORED PROCEDURE: dbo.PR_GET_ADMIN_USER_BY_ID
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_GET_ADMIN_USER_BY_ID
    @ADMIN_USER_ID BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        u.ADMIN_USER_ID,
        u.DOCTYPE,
        u.DOC_NO,
        u.EMAIL,
        u.FIRST_NAME,
        u.LAST_NAME,
        u.COUNTRY_CODE,
        u.MOBILE_NUMBER,
        u.PROFILE_IMAGE_URL,
        u.ADMIN_STATUS,
        u.IS_DELETED,
        u.DELETED_AT,
        u.LAST_LOGIN_AT,
        u.CREATED_AT,
        u.UPDATED_AT,
        ISNULL((
            SELECT STRING_AGG(r.ROLE_CODE, ',')
            FROM dbo.ADMIN_USER_ROLES ur
            INNER JOIN dbo.ADMIN_ROLES r ON ur.ROLE_ID = r.ROLE_ID
            WHERE ur.ADMIN_USER_ID = u.ADMIN_USER_ID
        ), '') AS ROLES_CSV
    FROM dbo.ADMIN_USERS u
    WHERE u.ADMIN_USER_ID = @ADMIN_USER_ID;
END;
GO

-- -----------------------------------------------------------------------------
-- 5. STORED PROCEDURE: dbo.PR_GET_ADMIN_ROLES
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_GET_ADMIN_ROLES
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        ROLE_ID,
        ROLE_CODE,
        ROLE_NAME,
        DESCRIPTION,
        IS_ACTIVE
    FROM dbo.ADMIN_ROLES
    WHERE IS_ACTIVE = 1
    ORDER BY ROLE_ID ASC;
END;
GO
