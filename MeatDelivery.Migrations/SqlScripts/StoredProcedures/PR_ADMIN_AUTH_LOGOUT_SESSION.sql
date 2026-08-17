-- =============================================================================
-- STORED PROCEDURE: dbo.PR_ADMIN_AUTH_LOGOUT_SESSION
-- Description: Revokes a single admin refresh session.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_ADMIN_AUTH_LOGOUT_SESSION
    @REFRESH_TOKEN_HASH VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.ADMIN_SESSIONS
    SET IS_ACTIVE = 0,
        UPDATED_AT = SYSUTCDATETIME()
    WHERE REFRESH_TOKEN_HASH = @REFRESH_TOKEN_HASH;
END;
GO
