-- =============================================================================
-- STORED PROCEDURE: dbo.PR_AUTH_REVOKE_ALL_SESSIONS
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_AUTH_REVOKE_ALL_SESSIONS
    @UserId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.USER_SESSIONS
    SET IS_ACTIVE = 0,
        UPDATED_AT = SYSUTCDATETIME()
    WHERE USER_ID = @UserId
      AND IS_ACTIVE = 1;
END;
GO
