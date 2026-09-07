-- =============================================================================
-- Migration: 0117_Update_PR_SAVE_COMPANY_HOLIDAY_Auto_CompanyConfigId.sql
-- Description: Updates PR_SAVE_COMPANY_HOLIDAY to automatically select active COMPANY_CONFIG_ID without parameter.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_SAVE_COMPANY_HOLIDAY
(
    @MODE                   VARCHAR(10),
    @COMPANY_HOLIDAY_ID     BIGINT          = NULL,
    @HOLIDAY_DATE           DATE            = NULL,
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

    DECLARE @COMPANY_CONFIG_ID BIGINT;

    -- Automatically select active company config ID
    SELECT TOP 1 @COMPANY_CONFIG_ID = COMPANY_CONFIG_ID
    FROM dbo.COMPANY_CONFIG
    WHERE IS_ACTIVE = 1;

    SET @COMPANY_CONFIG_ID = ISNULL(@COMPANY_CONFIG_ID, 1);

    IF UPPER(@MODE) = 'ADD'
    BEGIN
        IF @HOLIDAY_DATE IS NULL
        BEGIN
            THROW 50007, 'HolidayDate is required for ADD mode.', 1;
        END

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
            HOLIDAY_DATE        = ISNULL(@HOLIDAY_DATE, HOLIDAY_DATE),
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
