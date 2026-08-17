-- =============================================================================
-- STORED PROCEDURE: dbo.PR_ADMIN_AUTH_RECORD_LOGIN_FAILURE
-- Description: Increments failed attempts and locks account if threshold (5) is reached.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_ADMIN_AUTH_RECORD_LOGIN_FAILURE
    @ADMIN_USER_ID BIGINT,
    @MAX_ATTEMPTS INT = 5,
    @LOCKOUT_MINUTES INT = 15
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CurrentUtc DATETIME2 = SYSUTCDATETIME();
    DECLARE @NewFailedCount INT;
    DECLARE @NewLockedUntil DATETIME2 = NULL;

    SELECT @NewFailedCount = ISNULL(FAILED_LOGIN_COUNT, 0) + 1
    FROM dbo.ADMIN_USERS WITH (UPDLOCK, ROWLOCK)
    WHERE ADMIN_USER_ID = @ADMIN_USER_ID;

    IF @NewFailedCount >= @MAX_ATTEMPTS
    BEGIN
        SET @NewLockedUntil = DATEADD(MINUTE, @LOCKOUT_MINUTES, @CurrentUtc);
    END;

    UPDATE dbo.ADMIN_USERS
    SET 
        FAILED_LOGIN_COUNT = @NewFailedCount,
        LOCKED_UNTIL = @NewLockedUntil,
        UPDATED_AT = @CurrentUtc
    WHERE ADMIN_USER_ID = @ADMIN_USER_ID;

    SELECT 
        @NewFailedCount AS FailedLoginCount,
        @NewLockedUntil AS LockedUntil;
END;
GO
