-- =============================================================================
-- TABLE: dbo.COMPANY_HOLIDAYS
-- Description: Company holidays and off-schedule master table.
-- =============================================================================

CREATE TABLE dbo.COMPANY_HOLIDAYS
(
    COMPANY_HOLIDAY_ID      BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    COMPANY_CONFIG_ID       BIGINT               NOT NULL CONSTRAINT FK_COMPANY_HOLIDAYS_COMPANY REFERENCES dbo.COMPANY_CONFIG(COMPANY_CONFIG_ID),
    HOLIDAY_DATE            DATE                 NOT NULL,
    HOLIDAY_TYPE            VARCHAR(50)          NOT NULL DEFAULT 'HOLIDAY',
    IS_FULL_DAY             BIT                  NOT NULL DEFAULT 1,
    START_TIME              TIME                 NULL,
    END_TIME                TIME                 NULL,
    REASON_EN               NVARCHAR(250)        NULL,
    REASON_AR               NVARCHAR(250)        NULL,

    IS_ACTIVE               BIT                  NOT NULL DEFAULT 1,
    CREATED_AT              DATETIME2            NOT NULL DEFAULT SYSUTCDATETIME(),
    UPDATED_AT              DATETIME2            NULL
);
GO
