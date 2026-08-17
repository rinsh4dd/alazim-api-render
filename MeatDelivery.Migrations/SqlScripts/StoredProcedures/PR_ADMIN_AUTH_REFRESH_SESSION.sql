-- =============================================================================
-- STORED PROCEDURE: dbo.PR_ADMIN_AUTH_REFRESH_SESSION
-- Description: Validates current refresh session, revokes it, and registers the new session.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_ADMIN_AUTH_REFRESH_SESSION
    @CURRENT_REFRESH_TOKEN_HASH VARCHAR(500),
    @NEW_REFRESH_TOKEN_HASH VARCHAR(500),
    @DEVICE_ID VARCHAR(200) = NULL,
    @IP_ADDRESS VARCHAR(45) = NULL,
    @USER_AGENT NVARCHAR(500) = NULL,
    @NEW_EXPIRES_AT DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CurrentUtc DATETIME2 = SYSUTCDATETIME();
        DECLARE @SessionId BIGINT;
        DECLARE @AdminUserId BIGINT;
        DECLARE @IsActive BIT;
        DECLARE @ExpiresAt DATETIME2;
        DECLARE @AdminStatus VARCHAR(20);

        SELECT 
            @SessionId = s.ADMIN_SESSION_ID,
            @AdminUserId = s.ADMIN_USER_ID,
            @IsActive = s.IS_ACTIVE,
            @ExpiresAt = s.EXPIRES_AT,
            @AdminStatus = u.ADMIN_STATUS
        FROM dbo.ADMIN_SESSIONS s WITH (UPDLOCK, ROWLOCK)
        INNER JOIN dbo.ADMIN_USERS u ON u.ADMIN_USER_ID = s.ADMIN_USER_ID
        WHERE s.REFRESH_TOKEN_HASH = @CURRENT_REFRESH_TOKEN_HASH;

        IF @SessionId IS NULL OR @IsActive = 0
        BEGIN
            ROLLBACK TRANSACTION;
            RAISERROR('Invalid or inactive admin session.', 16, 1);
            RETURN;
        END;

        IF @CurrentUtc > @ExpiresAt
        BEGIN
            UPDATE dbo.ADMIN_SESSIONS
            SET IS_ACTIVE = 0, UPDATED_AT = @CurrentUtc
            WHERE ADMIN_SESSION_ID = @SessionId;

            ROLLBACK TRANSACTION;
            RAISERROR('Admin session has expired. Please log in again.', 16, 1);
            RETURN;
        END;

        IF @AdminStatus <> 'ACTIVE'
        BEGIN
            UPDATE dbo.ADMIN_SESSIONS
            SET IS_ACTIVE = 0, UPDATED_AT = @CurrentUtc
            WHERE ADMIN_USER_ID = @AdminUserId;

            ROLLBACK TRANSACTION;
            RAISERROR('Admin account is inactive or locked.', 16, 1);
            RETURN;
        END;

        -- Revoke old session
        UPDATE dbo.ADMIN_SESSIONS
        SET IS_ACTIVE = 0, UPDATED_AT = @CurrentUtc
        WHERE ADMIN_SESSION_ID = @SessionId;

        -- Create new session
        DECLARE @NewSessionId BIGINT;
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
            @AdminUserId,
            @NEW_REFRESH_TOKEN_HASH,
            @DEVICE_ID,
            @IP_ADDRESS,
            @USER_AGENT,
            1,
            @NEW_EXPIRES_AT,
            @CurrentUtc,
            @CurrentUtc
        );
        SET @NewSessionId = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        -- Return Admin Data
        SELECT 
            u.ADMIN_USER_ID AS AdminUserId,
            u.DOCTYPE AS DocType,
            u.DOC_NO AS DocNo,
            u.EMAIL AS Email,
            u.FIRST_NAME AS FirstName,
            u.LAST_NAME AS LastName,
            ISNULL(LTRIM(RTRIM(ISNULL(u.FIRST_NAME, '') + ' ' + ISNULL(u.LAST_NAME, ''))), '') AS FullName,
            @NewSessionId AS NewSessionId
        FROM dbo.ADMIN_USERS u
        WHERE u.ADMIN_USER_ID = @AdminUserId;

        -- Return Roles
        SELECT 
            r.ROLE_CODE AS RoleCode,
            r.ROLE_NAME AS RoleName
        FROM dbo.ADMIN_USER_ROLES ur
        INNER JOIN dbo.ROLES r ON r.ROLE_ID = ur.ROLE_ID AND r.IS_ACTIVE = 1
        WHERE ur.ADMIN_USER_ID = @AdminUserId AND ur.IS_ACTIVE = 1;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO
