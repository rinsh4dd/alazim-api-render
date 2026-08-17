-- =============================================================================
-- Migration: 0016_Create_PR_SAVE_ADMIN_ROLE
-- Date: 2026-08-17
-- Description: Creates PR_SAVE_ADMIN_ROLE for adding, editing, and
--              deleting roles in dbo.ROLES.
--              Supported modes: ADD, EDIT, DELETE.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_SAVE_ADMIN_ROLE
    @MODE           VARCHAR(10),
    @ROLE_ID        INT = NULL,
    @ROLE_CODE      VARCHAR(50) = NULL,
    @ROLE_NAME      NVARCHAR(100) = NULL,
    @DESCRIPTION    NVARCHAR(500) = NULL,
    @IS_ACTIVE      BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- =========================================================================
    -- MODE: ADD
    -- =========================================================================
    IF @MODE = 'ADD'
    BEGIN
        IF @ROLE_CODE IS NULL OR LTRIM(RTRIM(@ROLE_CODE)) = ''
        BEGIN
            THROW 50001, 'Role code is required.', 1;
        END;

        IF @ROLE_NAME IS NULL OR LTRIM(RTRIM(@ROLE_NAME)) = ''
        BEGIN
            THROW 50002, 'Role name is required.', 1;
        END;

        SET @ROLE_CODE = UPPER(LTRIM(RTRIM(@ROLE_CODE)));
        SET @ROLE_NAME = LTRIM(RTRIM(@ROLE_NAME));

        IF EXISTS
        (
            SELECT 1
            FROM dbo.ROLES
            WHERE ROLE_CODE = @ROLE_CODE
        )
        BEGIN
            THROW 50003, 'Role code already exists.', 1;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.ROLES
            WHERE ROLE_NAME = @ROLE_NAME
        )
        BEGIN
            THROW 50004, 'Role name already exists.', 1;
        END;

        INSERT INTO dbo.ROLES
        (
            ROLE_CODE,
            ROLE_NAME,
            DESCRIPTION,
            IS_ACTIVE
        )
        VALUES
        (
            @ROLE_CODE,
            @ROLE_NAME,
            @DESCRIPTION,
            ISNULL(@IS_ACTIVE, 1)
        );

        SET @ROLE_ID = CAST(SCOPE_IDENTITY() AS INT);

        SELECT
            ROLE_ID     AS RoleId,
            ROLE_CODE   AS RoleCode,
            ROLE_NAME   AS RoleName,
            DESCRIPTION AS Description,
            IS_ACTIVE   AS IsActive
        FROM dbo.ROLES
        WHERE ROLE_ID = @ROLE_ID;

        RETURN;
    END;

    -- =========================================================================
    -- MODE: EDIT
    -- =========================================================================
    IF @MODE = 'EDIT'
    BEGIN
        IF @ROLE_ID IS NULL OR @ROLE_ID <= 0
        BEGIN
            THROW 50005, 'RoleId is required for EDIT mode.', 1;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.ROLES
            WHERE ROLE_ID = @ROLE_ID
        )
        BEGIN
            THROW 50006, 'Role not found.', 1;
        END;

        IF @ROLE_CODE IS NOT NULL
        BEGIN
            SET @ROLE_CODE = UPPER(LTRIM(RTRIM(@ROLE_CODE)));
        END;

        IF @ROLE_NAME IS NOT NULL
        BEGIN
            SET @ROLE_NAME = LTRIM(RTRIM(@ROLE_NAME));
        END;

        IF @ROLE_CODE IS NOT NULL
           AND @ROLE_CODE <> ''
           AND EXISTS
           (
               SELECT 1
               FROM dbo.ROLES
               WHERE ROLE_CODE = @ROLE_CODE
                 AND ROLE_ID <> @ROLE_ID
           )
        BEGIN
            THROW 50007, 'Another role with this role code already exists.', 1;
        END;

        IF @ROLE_NAME IS NOT NULL
           AND @ROLE_NAME <> ''
           AND EXISTS
           (
               SELECT 1
               FROM dbo.ROLES
               WHERE ROLE_NAME = @ROLE_NAME
                 AND ROLE_ID <> @ROLE_ID
           )
        BEGIN
            THROW 50008, 'Another role with this role name already exists.', 1;
        END;

        UPDATE dbo.ROLES
        SET
            ROLE_CODE = CASE
                            WHEN @ROLE_CODE IS NOT NULL AND @ROLE_CODE <> ''
                            THEN @ROLE_CODE
                            ELSE ROLE_CODE
                        END,

            ROLE_NAME = CASE
                            WHEN @ROLE_NAME IS NOT NULL AND @ROLE_NAME <> ''
                            THEN @ROLE_NAME
                            ELSE ROLE_NAME
                        END,

            DESCRIPTION = ISNULL(@DESCRIPTION, DESCRIPTION),
            IS_ACTIVE = ISNULL(@IS_ACTIVE, IS_ACTIVE)

        WHERE ROLE_ID = @ROLE_ID;

        SELECT
            ROLE_ID     AS RoleId,
            ROLE_CODE   AS RoleCode,
            ROLE_NAME   AS RoleName,
            DESCRIPTION AS Description,
            IS_ACTIVE   AS IsActive
        FROM dbo.ROLES
        WHERE ROLE_ID = @ROLE_ID;

        RETURN;
    END;

    -- =========================================================================
    -- MODE: DELETE
    -- =========================================================================
    IF @MODE = 'DELETE'
    BEGIN
        IF @ROLE_ID IS NULL OR @ROLE_ID <= 0
        BEGIN
            THROW 50009, 'RoleId is required for DELETE mode.', 1;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.ROLES
            WHERE ROLE_ID = @ROLE_ID
        )
        BEGIN
            THROW 50010, 'Role not found.', 1;
        END;

        DELETE FROM dbo.ROLES
        OUTPUT
            DELETED.ROLE_ID     AS RoleId,
            DELETED.ROLE_CODE   AS RoleCode,
            DELETED.ROLE_NAME   AS RoleName,
            DELETED.DESCRIPTION AS Description,
            DELETED.IS_ACTIVE   AS IsActive
        WHERE ROLE_ID = @ROLE_ID;

        RETURN;
    END;

    -- =========================================================================
    -- INVALID MODE
    -- =========================================================================
    THROW 50011, 'Invalid mode. Expected ADD, EDIT, or DELETE.', 1;
END;
GO