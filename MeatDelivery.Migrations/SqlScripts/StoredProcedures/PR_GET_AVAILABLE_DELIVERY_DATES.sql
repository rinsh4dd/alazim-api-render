-- =============================================================================
-- STORED PROCEDURE: dbo.PR_GET_AVAILABLE_DELIVERY_DATES
-- Description: Retrieves available delivery dates from current UAE date (UTC+4) up to ADVANCE_DELIVERY_DAYS, excluding active full-day company holidays.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_GET_AVAILABLE_DELIVERY_DATES
AS
BEGIN
    SET NOCOUNT ON;

    -- Get current UAE Date (UTC+4)
    DECLARE @Today DATE = CAST(dbo.fn_GET_UAE_CURRENT_TIME() AS DATE);
    DECLARE @CompanyConfigId BIGINT;
    DECLARE @AdvanceDeliveryDays INT;

    SELECT
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
