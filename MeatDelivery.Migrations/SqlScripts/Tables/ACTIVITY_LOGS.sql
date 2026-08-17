-- =============================================================================
-- TABLE: dbo.ACTIVITY_LOGS
-- Description: System audit and activity tracking table.
-- =============================================================================

CREATE TABLE dbo.ACTIVITY_LOGS
(
    LOG_ID        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    USER_ID       BIGINT               NULL,
    ACTIVITY_TYPE VARCHAR(50)          NOT NULL,
    DESCRIPTION   NVARCHAR(500)        NOT NULL,
    IP_ADDRESS    VARCHAR(45)          NULL,
    DEVICE_ID     VARCHAR(200)         NULL,
    DEVICE_TYPE   VARCHAR(30)          NULL,
    CREATED_AT    DATETIME2            NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_ACTIVITY_LOGS_USER FOREIGN KEY (USER_ID) REFERENCES dbo.CUSTOMER_USERS(USER_ID)
);
GO
