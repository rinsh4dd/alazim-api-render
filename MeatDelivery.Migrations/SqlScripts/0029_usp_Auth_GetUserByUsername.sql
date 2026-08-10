CREATE OR ALTER PROCEDURE dbo.usp_Auth_GetUserByUsername
    @Username NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        u.UserId,
        u.UserName AS Username,
        u.Email,
        u.PasswordHash,
        u.PasswordSalt,
        u.IsActive,
        u.IsLocked,
        u.FailedLoginAttempts,
        u.LockoutEndOn AS LockoutEndUtc
    FROM dbo.Users u
    WHERE (u.UserName = @Username OR u.Email = @Username);
END;
