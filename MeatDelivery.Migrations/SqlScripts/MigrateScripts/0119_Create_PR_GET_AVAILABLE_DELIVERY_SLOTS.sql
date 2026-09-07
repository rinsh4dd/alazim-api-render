-- =============================================================================
-- Migration: 0119_Create_PR_GET_AVAILABLE_DELIVERY_SLOTS.sql
-- Description: Creates stored procedure PR_GET_AVAILABLE_DELIVERY_SLOTS to retrieve fixed 1-hour time slots categorized by periods.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_GET_AVAILABLE_DELIVERY_SLOTS
(
    @TARGET_DATE            DATE = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Get current UAE DateTime & Date
    DECLARE @UaeNow DATETIME2 = dbo.fn_GET_UAE_CURRENT_TIME();
    DECLARE @UaeDate DATE = CAST(@UaeNow AS DATE);
    DECLARE @UaeTime TIME = CAST(@UaeNow AS TIME);

    DECLARE @TargetDate DATE = ISNULL(@TARGET_DATE, @UaeDate);
    DECLARE @IsToday BIT = CASE WHEN @TargetDate = @UaeDate THEN 1 ELSE 0 END;

    DECLARE @CompanyConfigId BIGINT;
    SELECT TOP 1 @CompanyConfigId = COMPANY_CONFIG_ID
    FROM dbo.COMPANY_CONFIG
    WHERE IS_ACTIVE = 1;

    SET @CompanyConfigId = ISNULL(@CompanyConfigId, 1);

    -- 2. Fixed Master Slots Table
    DECLARE @MasterSlots TABLE
    (
        SlotId          VARCHAR(10),
        PeriodName      VARCHAR(20),
        StartTime       TIME,
        EndTime         TIME,
        DisplayTime     VARCHAR(30)
    );

    INSERT INTO @MasterSlots VALUES
    ('08-09', 'Morning', '08:00:00', '09:00:00', '08:00 AM - 09:00 AM'),
    ('09-10', 'Morning', '09:00:00', '10:00:00', '09:00 AM - 10:00 AM'),
    ('10-11', 'Morning', '10:00:00', '11:00:00', '10:00 AM - 11:00 AM'),
    ('11-12', 'Morning', '11:00:00', '12:00:00', '11:00 AM - 12:00 PM'),

    ('12-13', 'Noon',    '12:00:00', '13:00:00', '12:00 PM - 01:00 PM'),
    ('13-14', 'Noon',    '13:00:00', '14:00:00', '01:00 PM - 02:00 PM'),
    ('14-15', 'Noon',    '14:00:00', '15:00:00', '02:00 PM - 03:00 PM'),
    ('15-16', 'Noon',    '15:00:00', '16:00:00', '03:00 PM - 04:00 PM'),

    ('16-17', 'Evening', '16:00:00', '17:00:00', '04:00 PM - 05:00 PM'),
    ('17-18', 'Evening', '17:00:00', '18:00:00', '05:00 PM - 06:00 PM'),
    ('18-19', 'Evening', '18:00:00', '19:00:00', '06:00 PM - 07:00 PM'),
    ('19-20', 'Evening', '19:00:00', '20:00:00', '07:00 PM - 08:00 PM'),

    ('20-21', 'Night',   '20:00:00', '21:00:00', '08:00 PM - 09:00 PM'),
    ('21-22', 'Night',   '21:00:00', '22:00:00', '09:00 PM - 10:00 PM');

    -- 3. Check for Full-Day Holiday on Target Date
    DECLARE @IsFullDayHoliday BIT = 0;
    DECLARE @HolidayReasonEn NVARCHAR(250) = NULL;
    DECLARE @HolidayReasonAr NVARCHAR(250) = NULL;

    SELECT TOP 1
        @IsFullDayHoliday = IS_FULL_DAY,
        @HolidayReasonEn  = REASON_EN,
        @HolidayReasonAr  = REASON_AR
    FROM dbo.COMPANY_HOLIDAYS
    WHERE COMPANY_CONFIG_ID = @CompanyConfigId
      AND HOLIDAY_DATE = @TargetDate
      AND IS_ACTIVE = 1;

    -- 4. Return Slots with Availability Status
    SELECT
        m.SlotId                                                AS SlotId,
        m.PeriodName                                            AS PeriodName,
        m.StartTime                                             AS StartTime,
        m.EndTime                                               AS EndTime,
        m.DisplayTime                                           AS DisplayTime,
        CAST(
            CASE
                WHEN @IsFullDayHoliday = 1 THEN 0
                WHEN @IsToday = 1 AND m.StartTime <= @UaeTime THEN 0
                WHEN EXISTS (
                    SELECT 1 FROM dbo.COMPANY_HOLIDAYS h
                    WHERE h.COMPANY_CONFIG_ID = @CompanyConfigId
                      AND h.HOLIDAY_DATE = @TargetDate
                      AND h.IS_ACTIVE = 1
                      AND h.IS_FULL_DAY = 0
                      AND h.START_TIME <= m.EndTime
                      AND h.END_TIME >= m.StartTime
                ) THEN 0
                ELSE 1
            END AS BIT
        )                                                       AS IsAvailable,
        CASE
            WHEN @IsFullDayHoliday = 1 THEN ISNULL(@HolidayReasonEn, 'Company Holiday')
            WHEN @IsToday = 1 AND m.StartTime <= @UaeTime THEN 'Time slot passed'
            WHEN EXISTS (
                SELECT 1 FROM dbo.COMPANY_HOLIDAYS h
                WHERE h.COMPANY_CONFIG_ID = @CompanyConfigId
                  AND h.HOLIDAY_DATE = @TargetDate
                  AND h.IS_ACTIVE = 1
                  AND h.IS_FULL_DAY = 0
                  AND h.START_TIME <= m.EndTime
                  AND h.END_TIME >= m.StartTime
            ) THEN 'Unavailable during holiday hours'
            ELSE NULL
        END                                                     AS UnavailabilityReason
    FROM @MasterSlots m
    ORDER BY m.StartTime ASC;
END;
GO
