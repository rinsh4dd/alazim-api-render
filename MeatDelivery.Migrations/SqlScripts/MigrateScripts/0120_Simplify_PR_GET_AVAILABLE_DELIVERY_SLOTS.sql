-- =============================================================================
-- MIGRATION SCRIPT: 0120_Simplify_PR_GET_AVAILABLE_DELIVERY_SLOTS.sql
-- Description: Updates PR_GET_AVAILABLE_DELIVERY_SLOTS to generate dynamic 1-hour slots from COMPANY_WORKING_HOURS.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_GET_AVAILABLE_DELIVERY_SLOTS
(
    @TARGET_DATE DATE = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Now DATETIME2 = dbo.fn_GET_UAE_CURRENT_TIME();
    DECLARE @Today DATE = CAST(@Now AS DATE);
    DECLARE @TargetDate DATE = ISNULL(@TARGET_DATE, @Today);

    DECLARE @CompanyConfigId BIGINT;
    DECLARE @DeliveryStartTime TIME;
    DECLARE @DeliveryEndTime TIME;

    -- ---------------------------------------------------------
    -- 1. Active company
    -- ---------------------------------------------------------
    SELECT TOP 1
        @CompanyConfigId = COMPANY_CONFIG_ID
    FROM dbo.COMPANY_CONFIG
    WHERE IS_ACTIVE = 1;

    IF @CompanyConfigId IS NULL
        RETURN;

    -- Past date
    IF @TargetDate < @Today
        RETURN;

    -- ---------------------------------------------------------
    -- 2. Full-day holiday
    -- ---------------------------------------------------------
    IF EXISTS
    (
        SELECT 1
        FROM dbo.COMPANY_HOLIDAYS
        WHERE COMPANY_CONFIG_ID = @CompanyConfigId
          AND HOLIDAY_DATE = @TargetDate
          AND IS_FULL_DAY = 1
          AND IS_ACTIVE = 1
    )
        RETURN;

    -- ---------------------------------------------------------
    -- 3. Get weekday working hours
    -- Monday = 1 ... Sunday = 7
    -- ---------------------------------------------------------
    DECLARE @DayOfWeek INT =
        (DATEDIFF(DAY, '19000101', @TargetDate) % 7) + 1;

    SELECT
        @DeliveryStartTime = DELIVERY_START_TIME,
        @DeliveryEndTime = DELIVERY_END_TIME
    FROM dbo.COMPANY_WORKING_HOURS
    WHERE COMPANY_CONFIG_ID = @CompanyConfigId
      AND DAY_OF_WEEK = @DayOfWeek
      AND IS_WORKING_DAY = 1;

    IF @DeliveryStartTime IS NULL
       OR @DeliveryEndTime IS NULL
        RETURN;

    -- ---------------------------------------------------------
    -- 4. Generate 1-hour slots
    -- ---------------------------------------------------------
    DECLARE @StartDateTime DATETIME2 =
        DATEADD(
            SECOND,
            DATEDIFF(SECOND, CAST('00:00:00' AS TIME), @DeliveryStartTime),
            CAST(@TargetDate AS DATETIME2)
        );

    DECLARE @EndDateTime DATETIME2 =
        DATEADD(
            SECOND,
            DATEDIFF(SECOND, CAST('00:00:00' AS TIME), @DeliveryEndTime),
            CAST(@TargetDate AS DATETIME2)
        );

    ;WITH Slots AS
    (
        SELECT
            @StartDateTime AS SlotStart,
            DATEADD(HOUR, 1, @StartDateTime) AS SlotEnd

        UNION ALL

        SELECT
            SlotEnd,
            DATEADD(HOUR, 1, SlotEnd)
        FROM Slots
        WHERE DATEADD(HOUR, 1, SlotEnd) <= @EndDateTime
    )
    SELECT
        CAST(SlotStart AS TIME) AS StartTime,
        CAST(SlotEnd AS TIME) AS EndTime
    FROM Slots s
    WHERE
        s.SlotEnd <= @EndDateTime

        -- Remove passed/current slots for today
        AND (
            @TargetDate > @Today
            OR s.SlotStart > @Now
        )

        -- Remove partial holiday / closure overlaps
        AND NOT EXISTS
        (
            SELECT 1
            FROM dbo.COMPANY_HOLIDAYS h
            WHERE h.COMPANY_CONFIG_ID = @CompanyConfigId
              AND h.HOLIDAY_DATE = @TargetDate
              AND h.IS_ACTIVE = 1
              AND h.IS_FULL_DAY = 0

              AND h.START_TIME < CAST(s.SlotEnd AS TIME)
              AND h.END_TIME > CAST(s.SlotStart AS TIME)
        )

    ORDER BY SlotStart

    OPTION (MAXRECURSION 100);
END;
GO
