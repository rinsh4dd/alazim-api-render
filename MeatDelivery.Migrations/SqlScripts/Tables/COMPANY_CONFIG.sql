-- =============================================================================
-- TABLE: dbo.COMPANY_CONFIG
-- Description: Company configuration master table.
-- =============================================================================

CREATE TABLE dbo.COMPANY_CONFIG
(
    COMPANY_CONFIG_ID   BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    COMPANY_CODE        VARCHAR(50)          NOT NULL CONSTRAINT UQ_COMPANY_CONFIG_CODE UNIQUE,
    COMPANY_NAME        NVARCHAR(150)        NOT NULL,
    IS_ACTIVE           BIT                  NOT NULL DEFAULT 1,
    CREATED_AT          DATETIME2            NOT NULL DEFAULT SYSUTCDATETIME(),
    UPDATED_AT          DATETIME2            NULL
);
GO
