-- =============================================================================
-- Migration: 0111_Create_Company_Holiday_Procedures.sql
-- Description: Creates dbo.COMPANY_HOLIDAYS table and stored procedures PR_SAVE_COMPANY_HOLIDAY & PR_GET_COMPANY_HOLIDAYS.
-- =============================================================================

-- Drop legacy stored procedures and table if they exist
DROP PROCEDURE IF EXISTS dbo.PR_SAVE_COMPANY_OFF_DAY;
DROP PROCEDURE IF EXISTS dbo.PR_GET_COMPANY_OFF_DAYS;
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'COMPANY_OFF_DAYS' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    DROP TABLE dbo.COMPANY_OFF_DAYS;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'COMPANY_HOLIDAYS' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
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
END
GO

CREATE OR ALTER PROCEDURE dbo.PR_SAVE_COMPANY_HOLIDAY
(
    @MODE                   VARCHAR(10),
    @COMPANY_HOLIDAY_ID     BIGINT          = NULL,
    @COMPANY_CONFIG_ID      BIGINT,
    @HOLIDAY_DATE           DATE,
    @HOLIDAY_TYPE           VARCHAR(50)     = 'HOLIDAY',
    @IS_FULL_DAY            BIT             = 1,
    @START_TIME             TIME            = NULL,
    @END_TIME               TIME            = NULL,
    @REASON_EN              NVARCHAR(250)   = NULL,
    @REASON_AR              NVARCHAR(250)   = NULL,
    @IS_ACTIVE              BIT             = 1
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @COMPANY_CONFIG_ID <= 0 OR NOT EXISTS (SELECT 1 FROM dbo.COMPANY_CONFIG WHERE COMPANY_CONFIG_ID = @COMPANY_CONFIG_ID)
    BEGIN
        THROW 50001, 'Valid CompanyConfigId is required.', 1;
    END

    IF UPPER(@MODE) = 'ADD'
    BEGIN
        INSERT INTO dbo.COMPANY_HOLIDAYS
        (
            COMPANY_CONFIG_ID,
            HOLIDAY_DATE,
            HOLIDAY_TYPE,
            IS_FULL_DAY,
            START_TIME,
            END_TIME,
            REASON_EN,
            REASON_AR,
            IS_ACTIVE,
            CREATED_AT
        )
        VALUES
        (
            @COMPANY_CONFIG_ID,
            @HOLIDAY_DATE,
            ISNULL(@HOLIDAY_TYPE, 'HOLIDAY'),
            ISNULL(@IS_FULL_DAY, 1),
            @START_TIME,
            @END_TIME,
            @REASON_EN,
            @REASON_AR,
            ISNULL(@IS_ACTIVE, 1),
            SYSUTCDATETIME()
        );

        SELECT SCOPE_IDENTITY() AS CompanyHolidayId;
    END
    ELSE IF UPPER(@MODE) = 'EDIT'
    BEGIN
        IF @COMPANY_HOLIDAY_ID IS NULL OR @COMPANY_HOLIDAY_ID <= 0
        BEGIN
            THROW 50002, 'Valid CompanyHolidayId is required for EDIT mode.', 1;
        END

        IF NOT EXISTS (SELECT 1 FROM dbo.COMPANY_HOLIDAYS WHERE COMPANY_HOLIDAY_ID = @COMPANY_HOLIDAY_ID)
        BEGIN
            THROW 50003, 'Company holiday record not found.', 1;
        END

        UPDATE dbo.COMPANY_HOLIDAYS
        SET
            COMPANY_CONFIG_ID   = @COMPANY_CONFIG_ID,
            HOLIDAY_DATE        = @HOLIDAY_DATE,
            HOLIDAY_TYPE        = ISNULL(@HOLIDAY_TYPE, HOLIDAY_TYPE),
            IS_FULL_DAY         = ISNULL(@IS_FULL_DAY, IS_FULL_DAY),
            START_TIME          = @START_TIME,
            END_TIME            = @END_TIME,
            REASON_EN           = @REASON_EN,
            REASON_AR           = @REASON_AR,
            IS_ACTIVE           = ISNULL(@IS_ACTIVE, IS_ACTIVE),
            UPDATED_AT          = SYSUTCDATETIME()
        WHERE COMPANY_HOLIDAY_ID = @COMPANY_HOLIDAY_ID;

        SELECT @COMPANY_HOLIDAY_ID AS CompanyHolidayId;
    END
    ELSE IF UPPER(@MODE) = 'DELETE'
    BEGIN
        IF @COMPANY_HOLIDAY_ID IS NULL OR @COMPANY_HOLIDAY_ID <= 0
        BEGIN
            THROW 50005, 'Valid CompanyHolidayId is required for DELETE mode.', 1;
        END

        IF NOT EXISTS (SELECT 1 FROM dbo.COMPANY_HOLIDAYS WHERE COMPANY_HOLIDAY_ID = @COMPANY_HOLIDAY_ID)
        BEGIN
            THROW 50006, 'Company holiday record not found.', 1;
        END

        DELETE FROM dbo.COMPANY_HOLIDAYS
        WHERE COMPANY_HOLIDAY_ID = @COMPANY_HOLIDAY_ID;

        SELECT @COMPANY_HOLIDAY_ID AS CompanyHolidayId;
    END
    ELSE
    BEGIN
        THROW 50004, 'Invalid mode specified. Allowed values are ADD, EDIT, or DELETE.', 1;
    END
END;
GO

CREATE OR ALTER PROCEDURE dbo.PR_GET_COMPANY_HOLIDAYS
(
    @COMPANY_HOLIDAY_ID     BIGINT      = NULL,
    @COMPANY_CONFIG_ID      BIGINT      = NULL,
    @HOLIDAY_DATE           DATE        = NULL,
    @FROM_DATE              DATE        = NULL,
    @TO_DATE                DATE        = NULL,
    @HOLIDAY_TYPE           VARCHAR(50) = NULL,
    @IS_ACTIVE              BIT         = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        COMPANY_HOLIDAY_ID  AS CompanyHolidayId,
        COMPANY_CONFIG_ID   AS CompanyConfigId,
        HOLIDAY_DATE        AS HolidayDate,
        HOLIDAY_TYPE        AS HolidayType,
        IS_FULL_DAY         AS IsFullDay,
        START_TIME          AS StartTime,
        END_TIME            AS EndTime,
        REASON_EN           AS ReasonEn,
        REASON_AR           AS ReasonAr,
        IS_ACTIVE           AS IsActive,
        CREATED_AT          AS CreatedAt,
        UPDATED_AT          AS UpdatedAt
    FROM dbo.COMPANY_HOLIDAYS
    WHERE (@COMPANY_HOLIDAY_ID IS NULL OR COMPANY_HOLIDAY_ID = @COMPANY_HOLIDAY_ID)
      AND (@COMPANY_CONFIG_ID IS NULL OR COMPANY_CONFIG_ID = @COMPANY_CONFIG_ID)
      AND (@HOLIDAY_DATE IS NULL OR HOLIDAY_DATE = @HOLIDAY_DATE)
      AND (@FROM_DATE IS NULL OR HOLIDAY_DATE >= @FROM_DATE)
      AND (@TO_DATE IS NULL OR HOLIDAY_DATE <= @TO_DATE)
      AND (@HOLIDAY_TYPE IS NULL OR HOLIDAY_TYPE = @HOLIDAY_TYPE)
      AND (@IS_ACTIVE IS NULL OR IS_ACTIVE = @IS_ACTIVE)
    ORDER BY HOLIDAY_DATE DESC, CREATED_AT DESC;
END;
GO
