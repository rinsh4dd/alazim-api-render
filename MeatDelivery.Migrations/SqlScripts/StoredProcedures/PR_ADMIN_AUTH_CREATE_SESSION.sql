-- =============================================================================
-- STORED PROCEDURE: dbo.PR_ADMIN_AUTH_CREATE_SESSION
-- Description: Inserts a new admin session record.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_ADMIN_AUTH_CREATE_SESSION
    @ADMIN_USER_ID BIGINT,
    @REFRESH_TOKEN_HASH VARCHAR(500),
    @DEVICE_ID VARCHAR(200) = NULL,
    @IP_ADDRESS VARCHAR(45) = NULL,
    @USER_AGENT NVARCHAR(500) = NULL,
    @EXPIRES_AT DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CurrentUtc DATETIME2 = SYSUTCDATETIME();

    INSERT INTO dbo.ADMIN_SESSIONS
    (
        ADMIN_USER_ID,
        REFRESH_TOKEN_HASH,
        DEVICE_ID,
        IP_ADDRESS,
        USER_AGENT,
        IS_ACTIVE,
        EXPIRES_AT,
        LAST_ACTIVITY_AT,
        CREATED_AT
    )
    VALUES
    (
        @ADMIN_USER_ID,
        @REFRESH_TOKEN_HASH,
        @DEVICE_ID,
        @IP_ADDRESS,
        @USER_AGENT,
        1,
        @EXPIRES_AT,
        @CurrentUtc,
        @CurrentUtc
    );

    SELECT SCOPE_IDENTITY() AS AdminSessionId;
END;
GO
