CREATE OR ALTER PROCEDURE dbo.usp_Auth_GetUserContext
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. User Info
    SELECT
        u.UserId,
        u.UserName,
        u.Email,
        CONCAT(u.FirstName,
               CASE WHEN u.LastName IS NULL THEN '' ELSE ' ' + u.LastName END) AS FullName
    FROM dbo.Users u
    WHERE u.UserId = @UserId
      AND u.IsActive = 1;

    -- 2. Roles
    SELECT r.RoleName
    FROM dbo.UserRoles ur
    INNER JOIN dbo.Roles r ON ur.RoleId = r.RoleId
    WHERE ur.UserId = @UserId;

    -- 3. Permissions
    SELECT p.PermissionCode
    FROM dbo.UserRoles ur
    INNER JOIN dbo.RolePermissions rp ON ur.RoleId = rp.RoleId
    INNER JOIN dbo.Permissions p ON rp.PermissionId = p.PermissionId
    WHERE ur.UserId = @UserId
    ORDER BY p.PermissionCode;
END;
