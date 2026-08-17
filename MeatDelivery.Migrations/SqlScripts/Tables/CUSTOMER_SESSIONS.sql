-- =============================================================================
-- TABLE: dbo.CUSTOMER_SESSIONS (also known as dbo.USER_SESSIONS)
-- Description: Stores customer refresh-token sessions for mobile and web clients.
-- =============================================================================

CREATE TABLE dbo.CUSTOMER_SESSIONS
(
    SESSION_ID         BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CUSTOMER_USER_ID   BIGINT               NOT NULL,
    REFRESH_TOKEN_HASH VARCHAR(500)         NOT NULL,
    DEVICE_ID          VARCHAR(200)         NULL,
    DEVICE_TYPE        VARCHAR(30)          NULL,
    IP_ADDRESS         VARCHAR(45)          NULL,
    IS_ACTIVE          BIT                  NOT NULL DEFAULT 1,
    EXPIRES_AT         DATETIME2            NOT NULL,
    LAST_ACTIVITY_AT   DATETIME2            NULL,
    CREATED_AT         DATETIME2            NOT NULL DEFAULT SYSUTCDATETIME(),
    UPDATED_AT         DATETIME2            NULL,
    CONSTRAINT FK_CUSTOMER_SESSIONS_USER FOREIGN KEY (CUSTOMER_USER_ID) REFERENCES dbo.CUSTOMER_USERS(USER_ID)
);

CREATE NONCLUSTERED INDEX IX_CUSTOMER_SESSIONS_USER_ACTIVE 
ON dbo.CUSTOMER_SESSIONS(CUSTOMER_USER_ID, IS_ACTIVE);

CREATE NONCLUSTERED INDEX IX_CUSTOMER_SESSIONS_REFRESH_TOKEN 
ON dbo.CUSTOMER_SESSIONS(REFRESH_TOKEN_HASH, IS_ACTIVE);
GO
