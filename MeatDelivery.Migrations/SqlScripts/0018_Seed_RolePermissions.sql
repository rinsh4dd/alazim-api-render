INSERT INTO dbo.RolePermissions (RoleId, PermissionId)
SELECT r.RoleId, p.PermissionId
FROM dbo.Roles r
CROSS JOIN dbo.Permissions p
WHERE r.RoleName = 'SuperAdmin'
AND NOT EXISTS
(
    SELECT 1
    FROM dbo.RolePermissions rp
    WHERE rp.RoleId = r.RoleId
      AND rp.PermissionId = p.PermissionId
);