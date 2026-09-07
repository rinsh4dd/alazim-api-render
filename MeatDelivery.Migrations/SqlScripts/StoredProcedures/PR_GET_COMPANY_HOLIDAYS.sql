-- =============================================================================
-- STORED PROCEDURE: dbo.PR_GET_COMPANY_HOLIDAYS
-- Description: Retrieves list of company holidays matching criteria.
-- =============================================================================

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
