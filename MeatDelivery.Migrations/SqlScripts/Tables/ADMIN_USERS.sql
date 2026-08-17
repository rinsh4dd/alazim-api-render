-- =============================================================================
-- TABLE: dbo.ADMIN_USERS
-- Description: Stores back-office and administrative staff accounts.
-- Authentication: Email + BCrypt Password Hash
-- =============================================================================

CREATE TABLE dbo.ADMIN_USERS
(
    ADMIN_USER_ID            BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    DOCTYPE                  VARCHAR(20)          NULL,
    DOC_NO                   VARCHAR(50)          NULL,
    EMAIL                    VARCHAR(150)         NOT NULL,
    PASSWORD_HASH            VARCHAR(500)         NOT NULL,
    FIRST_NAME               NVARCHAR(100)        NOT NULL,
    LAST_NAME                NVARCHAR(100)        NULL,
    COUNTRY_CODE             VARCHAR(10)          NULL,
    MOBILE_NUMBER            VARCHAR(20)          NULL,
    PROFILE_IMAGE_URL        VARCHAR(500)         NULL,
    ADMIN_STATUS             VARCHAR(20)          NOT NULL DEFAULT 'ACTIVE',
    FAILED_LOGIN_COUNT       INT                  NOT NULL DEFAULT 0,
    LOCKED_UNTIL             DATETIME2            NULL,
    LAST_LOGIN_AT            DATETIME2            NULL,
    PASSWORD_CHANGED_AT      DATETIME2            NULL,
    CREATED_BY_ADMIN_USER_ID BIGINT               NULL,
    CREATED_AT               DATETIME2            NOT NULL DEFAULT SYSUTCDATETIME(),
    UPDATED_AT               DATETIME2            NULL,
    CONSTRAINT FK_ADMIN_USERS_CREATED_BY FOREIGN KEY (CREATED_BY_ADMIN_USER_ID) REFERENCES dbo.ADMIN_USERS(ADMIN_USER_ID)
);

CREATE UNIQUE NONCLUSTERED INDEX UQ_ADMIN_USERS_EMAIL 
ON dbo.ADMIN_USERS(EMAIL);
GO
