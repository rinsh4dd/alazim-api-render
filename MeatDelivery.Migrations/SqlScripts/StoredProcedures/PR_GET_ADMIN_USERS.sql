-- =============================================================================
-- STORED PROCEDURE: dbo.PR_GET_ADMIN_USERS
-- Description: Retrieves admin/staff users (optionally filtered by AdminUserId or RoleId).
-- =============================================================================

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
