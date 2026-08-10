CREATE OR ALTER PROCEDURE dbo.usp_Auth_ValidateRefreshToken
    @UserId UNIQUEIDENTIFIER,
    @RefreshToken NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.UserSessions
        WHERE UserId = @UserId
          AND RefreshToken = @RefreshToken
          AND RevokedOn IS NULL
          AND ExpiresOn > SYSUTCDATETIME()
    )
        SELECT CAST(1 AS BIT);
    ELSE
        SELECT CAST(0 AS BIT);
END;