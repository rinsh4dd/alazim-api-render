-- =============================================================================
-- STORED PROCEDURE: dbo.PR_GET_ADMIN_ROLES
-- Description: Retrieves active admin roles.
-- =============================================================================

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
    FROM dbo.ROLES
    WHERE IS_ACTIVE = 1
    ORDER BY ROLE_ID ASC;
END;
GO
