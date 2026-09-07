-- =============================================================================
-- MIGRATION SCRIPT: 0121_Add_Delivery_Times_And_Update_PR_GET_AVAILABLE_DELIVERY_SLOTS.sql
-- Description: Adds DELIVERY_START_TIME and DELIVERY_END_TIME to COMPANY_CONFIG and updates PR_GET_AVAILABLE_DELIVERY_SLOTS.
-- =============================================================================

IF NOT EXISTS (
    SELECT 1 FROM sys.columns 
    WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') 
      AND name = 'DELIVERY_START_TIME'
)
BEGIN
    ALTER TABLE dbo.COMPANY_CONFIG 
    ADD DELIVERY_START_TIME TIME NOT NULL DEFAULT '08:00:00';
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns 
    WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') 
      AND name = 'DELIVERY_END_TIME'
)
BEGIN
    ALTER TABLE dbo.COMPANY_CONFIG 
    ADD DELIVERY_END_TIME TIME NOT NULL DEFAULT '22:00:00';
END;
GO

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
    -- 1. Active company details
    -- ---------------------------------------------------------
    SELECT TOP 1
        @CompanyConfigId = COMPANY_CONFIG_ID,
        @DeliveryStartTime = ISNULL(DELIVERY_START_TIME, '08:00:00'),
        @DeliveryEndTime = ISNULL(DELIVERY_END_TIME, '22:00:00')
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

    IF @DeliveryStartTime IS NULL OR @DeliveryEndTime IS NULL
        RETURN;

    -- ---------------------------------------------------------
    -- 3. Generate 1-hour slots
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
