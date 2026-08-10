CREATE OR ALTER PROCEDURE dbo.usp_Auth_RevokeAllRefreshTokensByUserId
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.UserSessions
    SET RevokedOn = SYSUTCDATETIME()
    WHERE UserId = @UserId
      AND RevokedOn IS NULL;
END;
