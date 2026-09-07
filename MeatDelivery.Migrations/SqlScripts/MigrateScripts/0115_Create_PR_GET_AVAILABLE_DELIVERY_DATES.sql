-- =============================================================================
-- Migration: 0115_Create_PR_GET_AVAILABLE_DELIVERY_DATES.sql
-- Description: Creates stored procedure PR_GET_AVAILABLE_DELIVERY_DATES to fetch available delivery dates automatically using active COMPANY_CONFIG.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_GET_AVAILABLE_DELIVERY_DATES
(
    @CURRENT_DATE      DATE = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Today DATE = ISNULL(@CURRENT_DATE, CAST(SYSUTCDATETIME() AS DATE));
    DECLARE @CompanyConfigId BIGINT;
    DECLARE @AdvanceDeliveryDays INT;

    -- Automatically select active company config ID and AdvanceDeliveryDays count
    SELECT TOP 1
        @CompanyConfigId = COMPANY_CONFIG_ID,
        @AdvanceDeliveryDays = ADVANCE_DELIVERY_DAYS
    FROM dbo.COMPANY_CONFIG
    WHERE IS_ACTIVE = 1;

    SET @CompanyConfigId = ISNULL(@CompanyConfigId, 1);
    SET @AdvanceDeliveryDays = ISNULL(@AdvanceDeliveryDays, 30);

    ;WITH Dates AS
    (
        SELECT
            0 AS DayOffset,
            @Today AS DeliveryDate

        UNION ALL

        SELECT
            DayOffset + 1,
            DATEADD(DAY, 1, DeliveryDate)
        FROM Dates
        WHERE DayOffset + 1 < @AdvanceDeliveryDays
    )
    SELECT
        d.DeliveryDate AS [Date],
        DATENAME(WEEKDAY, d.DeliveryDate) AS DayName
    FROM Dates d
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.COMPANY_HOLIDAYS h
        WHERE h.COMPANY_CONFIG_ID = @CompanyConfigId
          AND h.HOLIDAY_DATE = d.DeliveryDate
          AND h.IS_FULL_DAY = 1
          AND h.IS_ACTIVE = 1
    )
    ORDER BY d.DeliveryDate;

END;
GO
