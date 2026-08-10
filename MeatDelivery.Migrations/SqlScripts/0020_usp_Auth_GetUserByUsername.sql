CREATE OR ALTER PROCEDURE dbo.usp_Auth_GetUserByUsername
    @Username NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        u.UserId,
        u.UserName,
        u.Email,
        u.PasswordHash,
        u.PasswordSalt,
        u.IsActive,
        u.IsLocked,
        u.FailedLoginAttempts,
        
        ur.RoleId
    FROM dbo.Users u
    LEFT JOIN dbo.UserRoles ur
        ON u.UserId = ur.UserId
    WHERE (u.UserName = @Username OR u.Email = @Username);
END;