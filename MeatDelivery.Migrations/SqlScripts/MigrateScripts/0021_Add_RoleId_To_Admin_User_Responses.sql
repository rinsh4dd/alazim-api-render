-- =============================================================================
-- Migration: 0021_Add_RoleId_To_Admin_User_Responses.sql
-- Description: Updates stored procedures PR_SAVE_ADMIN_USER and PR_GET_ADMIN_USERS
--              to include ROLE_ID in response result sets alongside ROLE (code).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. UPDATE PR_SAVE_ADMIN_USER
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
    @NATIONALITY            VARCHAR(100) = NULL,
    @DOB                    DATE = NULL,
    @ADDRESS                NVARCHAR(MAX) = NULL,
    @ADMIN_STATUS           VARCHAR(20) = 'ACTIVE',
    @ROLE_ID                INT = NULL,         -- Role ID from dbo.ROLES
    @ACTIONED_BY_ADMIN_ID   BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @OP_MODE VARCHAR(10) = UPPER(LTRIM(RTRIM(@MODE)));
    DECLARE @NEW_DOC_NO VARCHAR(50);
    DECLARE @DOC_TYPE VARCHAR(20) = 'ADM1';

    -- MODE: ADD
    IF @OP_MODE = 'ADD'
    BEGIN
        IF @EMAIL IS NULL OR LTRIM(RTRIM(@EMAIL)) = ''
        BEGIN
            THROW 50001, 'Email is required for new admin user.', 1;
        END;

        SET @EMAIL = LOWER(LTRIM(RTRIM(@EMAIL)));

        IF EXISTS (SELECT 1 FROM dbo.ADMIN_USERS WHERE EMAIL = @EMAIL AND IS_DELETED = 0)
        BEGIN
            THROW 50002, 'An active admin user with this email already exists.', 1;
        END;

        EXEC dbo.PR_GET_NEXT_DOC_NO 
            @DOCTYPE = @DOC_TYPE,
            @DOC_NO = @NEW_DOC_NO OUTPUT;

        BEGIN TRANSACTION;

        INSERT INTO dbo.ADMIN_USERS
        (
            DOCTYPE, DOC_NO, EMAIL, PASSWORD_HASH, FIRST_NAME, LAST_NAME,
            COUNTRY_CODE, MOBILE_NUMBER, PROFILE_IMAGE_URL, NATIONALITY, DOB, ADDRESS,
            ADMIN_STATUS, IS_DELETED, CREATED_BY_ADMIN_USER_ID, CREATED_AT
        )
        VALUES
        (
            @DOC_TYPE, @NEW_DOC_NO, @EMAIL, @PASSWORD_HASH, @FIRST_NAME, @LAST_NAME,
            @COUNTRY_CODE, @MOBILE_NUMBER, @PROFILE_IMAGE_URL, @NATIONALITY, @DOB, @ADDRESS,
            ISNULL(@ADMIN_STATUS, 'ACTIVE'), 0, @ACTIONED_BY_ADMIN_ID, SYSUTCDATETIME()
        );

        SET @ADMIN_USER_ID = SCOPE_IDENTITY();

        IF @ROLE_ID IS NOT NULL AND @ROLE_ID > 0
        BEGIN
            IF EXISTS (SELECT 1 FROM dbo.ROLES WHERE ROLE_ID = @ROLE_ID AND IS_ACTIVE = 1)
            BEGIN
                INSERT INTO dbo.ADMIN_USER_ROLES (ADMIN_USER_ID, ROLE_ID, ASSIGNED_BY_ADMIN_USER_ID, ASSIGNED_AT)
                VALUES (@ADMIN_USER_ID, @ROLE_ID, @ACTIONED_BY_ADMIN_ID, SYSUTCDATETIME());
            END;
        END;

        COMMIT TRANSACTION;

        SELECT 
            u.ADMIN_USER_ID, u.DOCTYPE, u.DOC_NO, u.EMAIL,
            u.FIRST_NAME, u.LAST_NAME, u.COUNTRY_CODE, u.MOBILE_NUMBER,
            u.PROFILE_IMAGE_URL, u.NATIONALITY, u.DOB, u.ADDRESS,
            u.ADMIN_STATUS, u.IS_DELETED, u.DELETED_AT,
            u.CREATED_AT, u.UPDATED_AT,
            (
                SELECT TOP 1 ur.ROLE_ID
                FROM dbo.ADMIN_USER_ROLES ur
                WHERE ur.ADMIN_USER_ID = u.ADMIN_USER_ID
            ) AS ROLE_ID,
            ISNULL((
                SELECT TOP 1 r.ROLE_CODE
                FROM dbo.ADMIN_USER_ROLES ur
                INNER JOIN dbo.ROLES r ON ur.ROLE_ID = r.ROLE_ID
                WHERE ur.ADMIN_USER_ID = u.ADMIN_USER_ID
            ), '') AS ROLE
        FROM dbo.ADMIN_USERS u
        WHERE u.ADMIN_USER_ID = @ADMIN_USER_ID;

        RETURN;
    END;

    -- MODE: EDIT
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
            NATIONALITY = ISNULL(@NATIONALITY, NATIONALITY),
            DOB = ISNULL(@DOB, DOB),
            ADDRESS = ISNULL(@ADDRESS, ADDRESS),
            ADMIN_STATUS = ISNULL(@ADMIN_STATUS, ADMIN_STATUS),
            UPDATED_AT = SYSUTCDATETIME()
        WHERE ADMIN_USER_ID = @ADMIN_USER_ID;

        IF @ROLE_ID IS NOT NULL AND @ROLE_ID > 0
        BEGIN
            DELETE FROM dbo.ADMIN_USER_ROLES WHERE ADMIN_USER_ID = @ADMIN_USER_ID;

            IF EXISTS (SELECT 1 FROM dbo.ROLES WHERE ROLE_ID = @ROLE_ID AND IS_ACTIVE = 1)
            BEGIN
                INSERT INTO dbo.ADMIN_USER_ROLES (ADMIN_USER_ID, ROLE_ID, ASSIGNED_BY_ADMIN_USER_ID, ASSIGNED_AT)
                VALUES (@ADMIN_USER_ID, @ROLE_ID, @ACTIONED_BY_ADMIN_ID, SYSUTCDATETIME());
            END;
        END;

        COMMIT TRANSACTION;

        SELECT 
            u.ADMIN_USER_ID, u.DOCTYPE, u.DOC_NO, u.EMAIL,
            u.FIRST_NAME, u.LAST_NAME, u.COUNTRY_CODE, u.MOBILE_NUMBER,
            u.PROFILE_IMAGE_URL, u.NATIONALITY, u.DOB, u.ADDRESS,
            u.ADMIN_STATUS, u.IS_DELETED, u.DELETED_AT,
            u.CREATED_AT, u.UPDATED_AT,
            (
                SELECT TOP 1 ur.ROLE_ID
                FROM dbo.ADMIN_USER_ROLES ur
                WHERE ur.ADMIN_USER_ID = u.ADMIN_USER_ID
            ) AS ROLE_ID,
            ISNULL((
                SELECT TOP 1 r.ROLE_CODE
                FROM dbo.ADMIN_USER_ROLES ur
                INNER JOIN dbo.ROLES r ON ur.ROLE_ID = r.ROLE_ID
                WHERE ur.ADMIN_USER_ID = u.ADMIN_USER_ID
            ), '') AS ROLE
        FROM dbo.ADMIN_USERS u
        WHERE u.ADMIN_USER_ID = @ADMIN_USER_ID;

        RETURN;
    END;

    -- MODE: DELETE
    IF @OP_MODE = 'DELETE'
    BEGIN
        IF @ADMIN_USER_ID IS NULL OR @ADMIN_USER_ID <= 0
        BEGIN
            THROW 50006, 'AdminUserId is required for deletion.', 1;
        END;

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
            u.ADMIN_USER_ID, u.DOCTYPE, u.DOC_NO, u.EMAIL,
            u.FIRST_NAME, u.LAST_NAME, u.COUNTRY_CODE, u.MOBILE_NUMBER,
            u.PROFILE_IMAGE_URL, u.NATIONALITY, u.DOB, u.ADDRESS,
            u.ADMIN_STATUS, u.IS_DELETED, u.DELETED_AT,
            u.CREATED_AT, u.UPDATED_AT,
            (
                SELECT TOP 1 ur.ROLE_ID
                FROM dbo.ADMIN_USER_ROLES ur
                WHERE ur.ADMIN_USER_ID = u.ADMIN_USER_ID
            ) AS ROLE_ID,
            ISNULL((
                SELECT TOP 1 r.ROLE_CODE
                FROM dbo.ADMIN_USER_ROLES ur
                INNER JOIN dbo.ROLES r ON ur.ROLE_ID = r.ROLE_ID
                WHERE ur.ADMIN_USER_ID = u.ADMIN_USER_ID
            ), '') AS ROLE
        FROM dbo.ADMIN_USERS u
        WHERE u.ADMIN_USER_ID = @ADMIN_USER_ID;

        RETURN;
    END;

    THROW 50008, 'Invalid operation mode. Expected ADD, EDIT, or DELETE.', 1;
END;
GO

-- -----------------------------------------------------------------------------
-- 2. UPDATE PR_GET_ADMIN_USERS
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_GET_ADMIN_USERS
    @ADMIN_USER_ID      BIGINT = NULL,
    @ROLE_ID            INT = NULL
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
        u.NATIONALITY,
        u.DOB,
        u.ADDRESS,
        u.ADMIN_STATUS,
        u.IS_DELETED,
        u.DELETED_AT,
        u.LAST_LOGIN_AT,
        u.CREATED_AT,
        u.UPDATED_AT,
        (
            SELECT TOP 1 ur.ROLE_ID
            FROM dbo.ADMIN_USER_ROLES ur
            WHERE ur.ADMIN_USER_ID = u.ADMIN_USER_ID
        ) AS ROLE_ID,
        ISNULL((
            SELECT TOP 1 r.ROLE_CODE
            FROM dbo.ADMIN_USER_ROLES ur
            INNER JOIN dbo.ROLES r ON ur.ROLE_ID = r.ROLE_ID
            WHERE ur.ADMIN_USER_ID = u.ADMIN_USER_ID
        ), '') AS ROLE
    FROM dbo.ADMIN_USERS u
    WHERE (@ADMIN_USER_ID IS NULL OR u.ADMIN_USER_ID = @ADMIN_USER_ID)
      AND (u.IS_DELETED = 0 OR u.IS_DELETED IS NULL)
      AND (
          @ROLE_ID IS NULL
          OR EXISTS (
              SELECT 1 
              FROM dbo.ADMIN_USER_ROLES ur2
              WHERE ur2.ADMIN_USER_ID = u.ADMIN_USER_ID
                AND ur2.ROLE_ID = @ROLE_ID
          )
      )
    ORDER BY u.ADMIN_USER_ID DESC;
END;
GO
