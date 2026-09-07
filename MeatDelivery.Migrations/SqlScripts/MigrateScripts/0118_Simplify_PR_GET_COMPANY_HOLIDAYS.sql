-- =============================================================================
-- Migration: 0118_Simplify_PR_GET_COMPANY_HOLIDAYS.sql
-- Description: Simplifies PR_GET_COMPANY_HOLIDAYS to fetch active company holidays automatically.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_GET_COMPANY_HOLIDAYS
(
    @COMPANY_HOLIDAY_ID     BIGINT      = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CompanyConfigId BIGINT;

    -- Automatically select active company config ID
    SELECT TOP 1 @CompanyConfigId = COMPANY_CONFIG_ID
    FROM dbo.COMPANY_CONFIG
    WHERE IS_ACTIVE = 1;

    SET @CompanyConfigId = ISNULL(@CompanyConfigId, 1);

    SELECT
        COMPANY_HOLIDAY_ID  AS CompanyHolidayId,
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
    WHERE COMPANY_CONFIG_ID = @CompanyConfigId
      AND (@COMPANY_HOLIDAY_ID IS NULL OR COMPANY_HOLIDAY_ID = @COMPANY_HOLIDAY_ID)
      AND IS_ACTIVE = 1
    ORDER BY HOLIDAY_DATE DESC, CREATED_AT DESC;
END;
GO
