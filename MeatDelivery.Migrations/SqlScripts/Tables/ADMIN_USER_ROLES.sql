-- =============================================================================
-- TABLE: dbo.ADMIN_USER_ROLES
-- Description: Many-to-many mapping between admin accounts and admin roles.
-- =============================================================================

CREATE TABLE dbo.ADMIN_USER_ROLES
(
    ADMIN_USER_ROLE_ID       BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ADMIN_USER_ID            BIGINT               NOT NULL,
    ROLE_ID                  INT                  NOT NULL,
    IS_ACTIVE                BIT                  NOT NULL DEFAULT 1,
    ASSIGNED_AT              DATETIME2            NOT NULL DEFAULT SYSUTCDATETIME(),
    ASSIGNED_BY_ADMIN_USER_ID BIGINT              NULL,
    UPDATED_AT               DATETIME2            NULL,
    CONSTRAINT FK_ADMIN_USER_ROLES_ADMIN FOREIGN KEY (ADMIN_USER_ID) REFERENCES dbo.ADMIN_USERS(ADMIN_USER_ID),
    CONSTRAINT FK_ADMIN_USER_ROLES_ROLE FOREIGN KEY (ROLE_ID) REFERENCES dbo.ROLES(ROLE_ID),
    CONSTRAINT FK_ADMIN_USER_ROLES_ASSIGNED_BY FOREIGN KEY (ASSIGNED_BY_ADMIN_USER_ID) REFERENCES dbo.ADMIN_USERS(ADMIN_USER_ID),
    CONSTRAINT UQ_ADMIN_USER_ROLES UNIQUE (ADMIN_USER_ID, ROLE_ID)
);
GO
