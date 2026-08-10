DECLARE @UserId UNIQUEIDENTIFIER;
DECLARE @RoleId UNIQUEIDENTIFIER;

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE UserName = 'admin')
BEGIN
    SET @UserId = NEWID();

    INSERT INTO dbo.Users
    (
        UserId, UserName, Email, PasswordHash,
        FirstName, LastName, IsActive
    )
    VALUES
    (
        @UserId,
        'admin',
        'admin@localhost.com',
        '$2a$11$9Uxtqm26PFrx0vOW4BbbtO2ljd14g9hUrCqfv2dHykp/cq8kEhhkW',
        'System',
        'Administrator',
        1
    );

    SELECT @RoleId = RoleId
    FROM dbo.Roles
    WHERE RoleName = 'SuperAdmin';

    INSERT INTO dbo.UserRoles (UserId, RoleId)
    VALUES (@UserId, @RoleId);
END