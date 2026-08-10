CREATE OR ALTER PROCEDURE dbo.usp_Auth_UpdateLastLogin
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.Users
    SET
        LastLoginOn = SYSUTCDATETIME(),
        FailedLoginAttempts = 0,
        UpdatedOn = SYSUTCDATETIME()
    WHERE UserId = @UserId;
END;