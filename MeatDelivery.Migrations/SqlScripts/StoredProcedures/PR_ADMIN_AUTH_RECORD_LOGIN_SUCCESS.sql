-- =============================================================================
-- STORED PROCEDURE: dbo.PR_ADMIN_AUTH_RECORD_LOGIN_SUCCESS
-- Description: Resets failed attempts, updates last login, and upgrades hash if provided.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_ADMIN_AUTH_RECORD_LOGIN_SUCCESS
    @ADMIN_USER_ID BIGINT,
    @UPGRADED_PASSWORD_HASH VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CurrentUtc DATETIME2 = SYSUTCDATETIME();

    UPDATE dbo.ADMIN_USERS
    SET 
        FAILED_LOGIN_COUNT = 0,
        LOCKED_UNTIL = NULL,
        LAST_LOGIN_AT = @CurrentUtc,
        PASSWORD_HASH = ISNULL(@UPGRADED_PASSWORD_HASH, PASSWORD_HASH),
        UPDATED_AT = @CurrentUtc
    WHERE ADMIN_USER_ID = @ADMIN_USER_ID;
END;
GO
