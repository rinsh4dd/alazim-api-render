-- =============================================================================
-- STORED PROCEDURE: dbo.PR_AUTH_LOGOUT_SESSION
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_AUTH_LOGOUT_SESSION
    @RefreshTokenHash VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.USER_SESSIONS
    SET IS_ACTIVE = 0,
        UPDATED_AT = SYSUTCDATETIME()
    WHERE REFRESH_TOKEN_HASH = @RefreshTokenHash
      AND IS_ACTIVE = 1;
END;
GO
