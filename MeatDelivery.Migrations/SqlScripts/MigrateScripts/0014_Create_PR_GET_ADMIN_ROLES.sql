-- =============================================================================
-- Migration: 0014_Create_PR_GET_ADMIN_ROLES
-- Date: 2026-08-17
-- Description: Retrieves all active admin roles and aliases database columns
--              to match AdminRoleDto properties for Dapper mapping.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_GET_ADMIN_ROLES
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        ROLE_ID     AS RoleId,
        ROLE_CODE   AS RoleCode,
        ROLE_NAME   AS RoleName,
        DESCRIPTION AS Description,
        IS_ACTIVE   AS IsActive
    FROM dbo.ROLES
    WHERE IS_ACTIVE = 1
    ORDER BY ROLE_ID ASC;
END;
GO