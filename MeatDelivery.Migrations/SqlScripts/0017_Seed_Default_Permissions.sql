INSERT INTO dbo.Permissions (PermissionCode, PermissionName, Module)
VALUES
('SYSTEM.FULL', 'Full System Access', 'System'),
('USERS.VIEW', 'View Users', 'Users'),
('USERS.CREATE', 'Create Users', 'Users'),
('USERS.EDIT', 'Edit Users', 'Users'),
('USERS.DELETE', 'Delete Users', 'Users'),
('ROLES.VIEW', 'View Roles', 'Security'),
('ROLES.MANAGE', 'Manage Roles', 'Security'),
('SETTINGS.VIEW', 'View Settings', 'Settings'),
('SETTINGS.MANAGE', 'Manage Settings', 'Settings');