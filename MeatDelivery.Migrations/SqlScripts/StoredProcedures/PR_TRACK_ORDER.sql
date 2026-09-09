-- =============================================================================
-- STORED PROCEDURE: dbo.PR_TRACK_ORDER
-- Description: Retrieves order tracking details with UAE Local Time (UTC+4).
-- Returns Order Header Snapshot and Status History Log.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_TRACK_ORDER
(
    @ORDER_ID           BIGINT,
    @CUSTOMER_USER_ID   BIGINT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @ORDER_ID IS NULL OR @ORDER_ID <= 0
    BEGIN
        RAISERROR('Valid OrderId is required.', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (
        SELECT 1 FROM dbo.ORDERS 
        WHERE ORDER_ID = @ORDER_ID 
          AND (@CUSTOMER_USER_ID IS NULL OR @CUSTOMER_USER_ID <= 0 OR CUSTOMER_USER_ID = @CUSTOMER_USER_ID)
    )
    BEGIN
        RAISERROR('Order not found', 16, 1);
        RETURN;
    END;

    -- Result Set 1: Order Header & Delivery Snapshot (with UAE Local Time PLACED_AT)
    SELECT 
        o.ORDER_ID AS OrderId,
        o.DOC_NO AS DocNo,
        o.ORDER_STATUS AS CurrentStatus,
        o.PAYMENT_METHOD AS PaymentMethod,
        o.PAYMENT_STATUS AS PaymentStatus,
        o.TOTAL_AMOUNT AS TotalAmount,
        DATEADD(HOUR, 4, o.PLACED_AT) AS PlacedAtUae,
        o.DELIVERY_DATE AS DeliveryDate,
        o.DELIVERY_SLOT_START_TIME AS DeliverySlotStartTime,
        o.DELIVERY_SLOT_END_TIME AS DeliverySlotEndTime,
        o.DELIVERY_CONTACT_NUMBER AS DeliveryContactNumber,
        ISNULL(NULLIF(RTRIM(LTRIM(
            ISNULL(NULLIF(o.DELIVERY_VILLA_OR_FLAT_NO, '') + ', ', '') +
            ISNULL(NULLIF(o.DELIVERY_BUILDING_NAME, '') + ', ', '') +
            ISNULL(NULLIF(o.DELIVERY_STREET, '') + ', ', '') +
            ISNULL(NULLIF(o.DELIVERY_AREA, '') + ', ', '') +
            ISNULL(o.DELIVERY_CITY, '')
        )), ''), 'Delivery Address') AS DeliveryAddressSummary,
        o.DELIVERY_LATITUDE AS Latitude,
        o.DELIVERY_LONGITUDE AS Longitude
    FROM dbo.ORDERS o
    WHERE o.ORDER_ID = @ORDER_ID;

    -- Result Set 2: Order Status History Log (with UAE Local Time)
    SELECT 
        h.ORDER_STATUS AS OrderStatus,
        h.REMARKS AS Remarks,
        DATEADD(HOUR, 4, h.CREATED_AT) AS CreatedAtUae
    FROM dbo.ORDER_STATUS_HISTORY h
    WHERE h.ORDER_ID = @ORDER_ID
    ORDER BY h.CREATED_AT ASC, h.ORDER_STATUS_HISTORY_ID ASC;
END;
GO
