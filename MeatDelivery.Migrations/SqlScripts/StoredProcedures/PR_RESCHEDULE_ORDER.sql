IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PR_RESCHEDULE_ORDER]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[PR_RESCHEDULE_ORDER];
GO

CREATE PROCEDURE [dbo].[PR_RESCHEDULE_ORDER]
    @P_ORDER_ID             BIGINT,
    @P_CUSTOMER_USER_ID     BIGINT,
    @P_NEW_DELIVERY_DATE    DATE,
    @P_NEW_START_TIME       TIME,
    @P_NEW_END_TIME         TIME,
    @P_REMARKS              NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Validate Order Existence & Customer Ownership
    IF NOT EXISTS (SELECT 1 FROM dbo.ORDERS WHERE ORDER_ID = @P_ORDER_ID)
    BEGIN
        RAISERROR('Order not found.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (
        SELECT 1 FROM dbo.ORDERS WHERE ORDER_ID = @P_ORDER_ID AND CUSTOMER_USER_ID = @P_CUSTOMER_USER_ID
    )
    BEGIN
        RAISERROR('Order not found or access denied.', 16, 1);
        RETURN;
    END

    -- 2. Fetch Current Details & Validate Reschedule Constraints
    DECLARE @V_PREVIOUS_STATUS NVARCHAR(50);
    DECLARE @V_DOC_NO VARCHAR(50);
    DECLARE @V_PREVIOUS_DATE DATE;
    DECLARE @V_PREVIOUS_START_TIME TIME;
    DECLARE @V_PREVIOUS_END_TIME TIME;

    SELECT 
        @V_PREVIOUS_STATUS = ORDER_STATUS,
        @V_DOC_NO = DOC_NO,
        @V_PREVIOUS_DATE = DELIVERY_DATE,
        @V_PREVIOUS_START_TIME = DELIVERY_SLOT_START_TIME,
        @V_PREVIOUS_END_TIME = DELIVERY_SLOT_END_TIME
    FROM dbo.ORDERS 
    WHERE ORDER_ID = @P_ORDER_ID;

    IF @V_PREVIOUS_STATUS IN ('PROCESSING', 'OUT_FOR_DELIVERY', 'DELIVERED')
    BEGIN
        RAISERROR('Order cannot be rescheduled once processing has started or after delivery.', 16, 1);
        RETURN;
    END

    IF @V_PREVIOUS_STATUS = 'CANCELLED'
    BEGIN
        RAISERROR('Order is cancelled and cannot be rescheduled.', 16, 1);
        RETURN;
    END

    -- Validate Target Date
    DECLARE @V_TODAY DATE = CAST(dbo.fn_GET_UAE_CURRENT_TIME() AS DATE);
    IF @P_NEW_DELIVERY_DATE < @V_TODAY
    BEGIN
        RAISERROR('New delivery date cannot be in the past.', 16, 1);
        RETURN;
    END

    -- Validate Full-Day Company Holiday
    IF EXISTS (
        SELECT 1 
        FROM dbo.COMPANY_HOLIDAYS 
        WHERE HOLIDAY_DATE = @P_NEW_DELIVERY_DATE 
          AND IS_FULL_DAY = 1 
          AND IS_ACTIVE = 1
    )
    BEGIN
        RAISERROR('Selected date is a company holiday.', 16, 1);
        RETURN;
    END

    -- 3. Perform Reschedule Update
    UPDATE dbo.ORDERS
    SET 
        DELIVERY_DATE = @P_NEW_DELIVERY_DATE,
        DELIVERY_SLOT_START_TIME = @P_NEW_START_TIME,
        DELIVERY_SLOT_END_TIME = @P_NEW_END_TIME,
        UPDATED_AT = SYSUTCDATETIME()
    WHERE ORDER_ID = @P_ORDER_ID;

    -- 4. Record Status History / Audit Log
    DECLARE @V_REMARKS NVARCHAR(750);
    SET @V_REMARKS = CONCAT('Delivery rescheduled to ', CONVERT(VARCHAR, @P_NEW_DELIVERY_DATE, 23), ' (', CONVERT(VARCHAR(5), @P_NEW_START_TIME, 108), '-', CONVERT(VARCHAR(5), @P_NEW_END_TIME, 108), ')', CASE WHEN @P_REMARKS IS NOT NULL AND LEN(@P_REMARKS) > 0 THEN CONCAT(' - ', @P_REMARKS) ELSE '' END);

    INSERT INTO dbo.ORDER_STATUS_HISTORY (
        ORDER_ID,
        DOC_NO,
        ORDER_STATUS,
        REMARKS,
        CREATED_AT
    ) VALUES (
        @P_ORDER_ID,
        @V_DOC_NO,
        @V_PREVIOUS_STATUS,
        @V_REMARKS,
        SYSUTCDATETIME()
    );

    -- 5. Return Output Response
    SELECT 
        @P_ORDER_ID AS OrderId,
        @V_DOC_NO AS DocNo,
        @V_PREVIOUS_DATE AS PreviousDeliveryDate,
        @V_PREVIOUS_START_TIME AS PreviousSlotStartTime,
        @V_PREVIOUS_END_TIME AS PreviousSlotEndTime,
        @P_NEW_DELIVERY_DATE AS NewDeliveryDate,
        @P_NEW_START_TIME AS NewSlotStartTime,
        @P_NEW_END_TIME AS NewSlotEndTime,
        dbo.fn_GET_UAE_CURRENT_TIME() AS RescheduledAtUae;
END
GO
