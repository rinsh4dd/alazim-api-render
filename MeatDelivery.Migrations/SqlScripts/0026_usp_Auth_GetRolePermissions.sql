CREATE OR ALTER PROCEDURE dbo.usp_Auth_GetRolePermissions
    @RoleId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT p.PermissionCode
    FROM dbo.RolePermissions rp
    INNER JOIN dbo.Permissions p
        ON rp.PermissionId = p.PermissionId
    WHERE rp.RoleId = @RoleId
    ORDER BY p.PermissionCode;
END;