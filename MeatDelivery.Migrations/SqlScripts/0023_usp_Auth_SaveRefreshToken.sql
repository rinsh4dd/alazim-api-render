CREATE OR ALTER PROCEDURE dbo.usp_Auth_SaveRefreshToken
    @SessionId UNIQUEIDENTIFIER,
    @UserId UNIQUEIDENTIFIER,
    @RefreshToken NVARCHAR(500),
    @IpAddress NVARCHAR(50) = NULL,
    @UserAgent NVARCHAR(1000) = NULL,
    @ExpiresOn DATETIME2(7)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.UserSessions
    (
        SessionId,
        UserId,
        RefreshToken,
        IpAddress,
        UserAgent,
        LoginTime,
        ExpiresOn
    )
    VALUES
    (
        @SessionId,
        @UserId,
        @RefreshToken,
        @IpAddress,
        @UserAgent,
        SYSUTCDATETIME(),
        @ExpiresOn
    );
END;