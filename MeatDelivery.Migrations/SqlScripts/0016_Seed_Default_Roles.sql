INSERT INTO dbo.Roles (RoleName, Description, IsSystemRole)
SELECT 'SuperAdmin', 'Full system access', 1
WHERE NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = 'SuperAdmin');

INSERT INTO dbo.Roles (RoleName, Description, IsSystemRole)
SELECT 'Administrator', 'Administrative access', 1
WHERE NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = 'Administrator');

INSERT INTO dbo.Roles (RoleName, Description, IsSystemRole)
SELECT 'Manager', 'Management access', 1
WHERE NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = 'Manager');

INSERT INTO dbo.Roles (RoleName, Description, IsSystemRole)
SELECT 'Cashier', 'POS operations', 1
WHERE NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = 'Cashier');