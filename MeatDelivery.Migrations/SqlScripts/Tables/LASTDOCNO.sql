-- =============================================================================
-- TABLE: dbo.LASTDOCNO
-- Description: Stores current sequence number for each document type and period.
-- =============================================================================

CREATE TABLE dbo.LASTDOCNO
(
    DOCTYPE                 VARCHAR(20)          NOT NULL,
    PERIOD_KEY              VARCHAR(20)          NOT NULL,
    DOCNO                   BIGINT               NOT NULL,
    LAST_GENERATED_DOC_NO   VARCHAR(50)          NULL,
    LAST_GENERATED_AT       DATETIME2            NULL,
    UPDATED_AT              DATETIME2            NOT NULL DEFAULT SYSUTCDATETIME(),
    ROW_VERSION             ROWVERSION           NOT NULL,
    CONSTRAINT PK_LASTDOCNO PRIMARY KEY (DOCTYPE, PERIOD_KEY),
    CONSTRAINT FK_LASTDOCNO_MDOC FOREIGN KEY (DOCTYPE) REFERENCES dbo.M_DOC_NO(DOCTYPE)
);
GO
