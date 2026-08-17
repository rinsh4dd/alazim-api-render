-- =============================================================================
-- STORED PROCEDURE: dbo.PR_AUTH_REFRESH_TOKEN_SESSION
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_AUTH_REFRESH_TOKEN_SESSION
    @OldRefreshTokenHash VARCHAR(500),
    @NewRefreshTokenHash VARCHAR(500),
    @DeviceId VARCHAR(200) = NULL,
    @DeviceType VARCHAR(30) = NULL,
    @IpAddress VARCHAR(45) = NULL,
    @SessionExpiresAt DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @UserId BIGINT;
    DECLARE @SessionId BIGINT;

    SELECT TOP 1 
        @SessionId = s.SESSION_ID,
        @UserId = s.USER_ID
    FROM dbo.USER_SESSIONS s
    WHERE s.REFRESH_TOKEN_HASH = @OldRefreshTokenHash
      AND s.IS_ACTIVE = 1
      AND s.EXPIRES_AT > SYSUTCDATETIME();

    IF @SessionId IS NULL
    BEGIN
        RAISERROR('Invalid or expired refresh token session.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;

    -- Deactivate old session
    UPDATE dbo.USER_SESSIONS
    SET IS_ACTIVE = 0,
        UPDATED_AT = SYSUTCDATETIME()
    WHERE SESSION_ID = @SessionId;

    -- Create new session
    DECLARE @NewSessionId BIGINT;

    INSERT INTO dbo.USER_SESSIONS
    (
        USER_ID,
        REFRESH_TOKEN_HASH,
        DEVICE_ID,
        DEVICE_TYPE,
        IP_ADDRESS,
        IS_ACTIVE,
        EXPIRES_AT,
        LAST_ACTIVITY_AT,
        CREATED_AT
    )
    VALUES
    (
        @UserId,
        @NewRefreshTokenHash,
        @DeviceId,
        @DeviceType,
        @IpAddress,
        1,
        @SessionExpiresAt,
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    );

    SET @NewSessionId = SCOPE_IDENTITY();

    -- Update last login
    UPDATE dbo.CUSTOMER_USERS
    SET LAST_LOGIN_AT = SYSUTCDATETIME(),
        UPDATED_AT = SYSUTCDATETIME()
    WHERE USER_ID = @UserId;

    COMMIT TRANSACTION;

    -- Return expected RefreshTokenSessionResult payload
    SELECT 
        u.USER_ID AS UserId,
        ISNULL(LTRIM(RTRIM(ISNULL(u.FIRST_NAME, '') + ' ' + ISNULL(u.LAST_NAME, ''))), '') AS FullName,
        u.COUNTRY_CODE AS CountryCode,
        u.MOBILE_NUMBER AS MobileNumber,
        @NewSessionId AS SessionId
    FROM dbo.CUSTOMER_USERS u
    WHERE u.USER_ID = @UserId;
END;
GO
