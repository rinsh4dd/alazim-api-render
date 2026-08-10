CREATE OR ALTER PROCEDURE dbo.usp_Auth_RevokeRefreshToken
    @RefreshToken NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.UserSessions
    SET RevokedOn = SYSUTCDATETIME()
    WHERE RefreshToken = @RefreshToken
      AND RevokedOn IS NULL;
END;