-- =============================================================================
-- TABLE: dbo.M_DOC_NO
-- Description: Master document numbering configuration.
-- Master Families: CRT, ORD, INV, PAY, REF, STK, CPN, NTF, CUS
-- =============================================================================

CREATE TABLE dbo.M_DOC_NO
(
    M_DOC_NO_ID                 BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    MDOC                        VARCHAR(20)          NOT NULL,
    DOCTYPE                     VARCHAR(20)          NOT NULL CONSTRAINT UQ_M_DOC_NO_DOCTYPE UNIQUE,
    DESCRIPTION                 NVARCHAR(150)        NOT NULL,
    COMPANY_CONFIG_ID           BIGINT               NULL CONSTRAINT FK_M_DOC_NO_COMPANY REFERENCES dbo.COMPANY_CONFIG(COMPANY_CONFIG_ID),
    PREFIX                      VARCHAR(20)          NULL,
    SUFFIX                      VARCHAR(20)          NULL,
    DIGIT_NO                    INT                  NOT NULL,
    START_DOCNO                 BIGINT               NOT NULL DEFAULT 0,
    PERIODWISE_YN               CHAR(1)              NOT NULL DEFAULT 'N',
    PERIOD_TYPE                 VARCHAR(20)          NULL DEFAULT 'NONE',
    DOC_PRINT                   VARCHAR(100)         NULL,
    IS_ACTIVE                   BIT                  NOT NULL DEFAULT 1,
    CREATED_BY_ADMIN_USER_ID    BIGINT               NULL,
    CREATED_AT                  DATETIME2            NOT NULL DEFAULT SYSUTCDATETIME(),
    UPDATED_AT                  DATETIME2            NULL
);
GO
