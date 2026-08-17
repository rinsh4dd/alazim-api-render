-- =============================================================================
-- TABLE: dbo.ADMIN_SESSIONS
-- Description: Stores admin refresh-token sessions independently from customer sessions.
-- =============================================================================

CREATE TABLE dbo.ADMIN_SESSIONS
(
    ADMIN_SESSION_ID   BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ADMIN_USER_ID      BIGINT               NOT NULL,
    REFRESH_TOKEN_HASH VARCHAR(500)         NOT NULL,
    DEVICE_ID          VARCHAR(200)         NULL,
    IP_ADDRESS         VARCHAR(45)          NULL,
    USER_AGENT         NVARCHAR(500)        NULL,
    IS_ACTIVE          BIT                  NOT NULL DEFAULT 1,
    EXPIRES_AT         DATETIME2            NOT NULL,
    LAST_ACTIVITY_AT   DATETIME2            NULL,
    CREATED_AT         DATETIME2            NOT NULL DEFAULT SYSUTCDATETIME(),
    UPDATED_AT         DATETIME2            NULL,
    CONSTRAINT FK_ADMIN_SESSIONS_ADMIN FOREIGN KEY (ADMIN_USER_ID) REFERENCES dbo.ADMIN_USERS(ADMIN_USER_ID)
);

CREATE NONCLUSTERED INDEX IX_ADMIN_SESSIONS_ADMIN_ACTIVE 
ON dbo.ADMIN_SESSIONS(ADMIN_USER_ID, IS_ACTIVE);

CREATE NONCLUSTERED INDEX IX_ADMIN_SESSIONS_REFRESH_TOKEN 
ON dbo.ADMIN_SESSIONS(REFRESH_TOKEN_HASH, IS_ACTIVE);
GO
