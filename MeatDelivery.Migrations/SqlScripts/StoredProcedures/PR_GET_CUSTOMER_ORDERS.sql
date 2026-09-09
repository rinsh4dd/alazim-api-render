-- =============================================================================
-- STORED PROCEDURE: dbo.PR_GET_CUSTOMER_ORDERS
-- Description: Retrieves orders, items, customizations, and status history for a customer.
-- Supports pagination, filtering by OrderStatus, or fetching a single OrderId.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_GET_CUSTOMER_ORDERS
(
    @CUSTOMER_USER_ID   BIGINT,
    @ORDER_ID           BIGINT          = NULL,
    @ORDER_STATUS       VARCHAR(30)     = NULL,
    @PAGE_NUMBER        INT             = 1,
    @PAGE_SIZE          INT             = 20
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @CUSTOMER_USER_ID IS NULL OR @CUSTOMER_USER_ID <= 0
    BEGIN
        RAISERROR('Valid CustomerUserId is required.', 16, 1);
        RETURN;
    END;

    IF @PAGE_NUMBER IS NULL OR @PAGE_NUMBER <= 0 SET @PAGE_NUMBER = 1;
    IF @PAGE_SIZE IS NULL OR @PAGE_SIZE <= 0 SET @PAGE_SIZE = 20;

    DECLARE @OFFSET INT = (@PAGE_NUMBER - 1) * @PAGE_SIZE;

    -- Temporary table to hold filtered OrderIds
    CREATE TABLE #TargetOrders
    (
        ORDER_ID BIGINT PRIMARY KEY
    );

    IF @ORDER_ID IS NOT NULL AND @ORDER_ID > 0
    BEGIN
        INSERT INTO #TargetOrders (ORDER_ID)
        SELECT ORDER_ID
        FROM dbo.ORDERS
        WHERE ORDER_ID = @ORDER_ID AND CUSTOMER_USER_ID = @CUSTOMER_USER_ID;
    END
    ELSE
    BEGIN
        INSERT INTO #TargetOrders (ORDER_ID)
        SELECT ORDER_ID
        FROM dbo.ORDERS
        WHERE CUSTOMER_USER_ID = @CUSTOMER_USER_ID
          AND (@ORDER_STATUS IS NULL OR LTRIM(RTRIM(@ORDER_STATUS)) = '' OR ORDER_STATUS = @ORDER_STATUS)
        ORDER BY PLACED_AT DESC, ORDER_ID DESC
        OFFSET @OFFSET ROWS FETCH NEXT @PAGE_SIZE ROWS ONLY;
    END;

    -- Result Set 1: Orders Header & Delivery Details
    SELECT 
        o.ORDER_ID AS OrderId,
        o.DOC_NO AS DocNo,
        o.CUSTOMER_USER_ID AS CustomerUserId,
        o.ADDRESS_ID AS AddressId,
        o.ORDER_STATUS AS OrderStatus,
        o.PAYMENT_METHOD AS PaymentMethod,
        o.PAYMENT_STATUS AS PaymentStatus,
        o.CURRENCY_CODE AS CurrencyCode,
        o.SUBTOTAL AS Subtotal,
        o.PRODUCT_DISCOUNT_TOTAL AS ProductDiscountTotal,
        o.COUPON_ID AS CouponId,
        o.COUPON_DISCOUNT AS CouponDiscount,
        o.DELIVERY_CHARGE AS DeliveryCharge,
        o.VAT_AMOUNT AS VatAmount,
        o.TOTAL_AMOUNT AS TotalAmount,
        o.PLACED_AT AS PlacedAt,
        o.CREATED_AT AS CreatedAt,
        
        -- Delivery Schedule
        o.DELIVERY_DATE AS DeliveryDate,
        o.DELIVERY_SLOT_START_TIME AS DeliverySlotStartTime,
        o.DELIVERY_SLOT_END_TIME AS DeliverySlotEndTime,
        
        -- Delivery Address Snapshot
        o.DELIVERY_CONTACT_NUMBER AS DeliveryContactNumber,
        o.DELIVERY_ADDRESS_TYPE AS DeliveryAddressType,
        o.DELIVERY_BUILDING_NAME AS DeliveryBuildingName,
        o.DELIVERY_VILLA_OR_FLAT_NO AS DeliveryVillaOrFlatNo,
        o.DELIVERY_STREET AS DeliveryStreet,
        o.DELIVERY_AREA AS DeliveryArea,
        o.DELIVERY_CITY AS DeliveryCity,
        o.DELIVERY_LANDMARK AS DeliveryLandmark,
        o.DELIVERY_POSTAL_CODE AS DeliveryPostalCode,
        o.DELIVERY_EMIRATE AS DeliveryEmirate,
        o.DELIVERY_LATITUDE AS DeliveryLatitude,
        o.DELIVERY_LONGITUDE AS DeliveryLongitude,
        o.DELIVERY_INSTRUCTIONS AS DeliveryInstructions
    FROM dbo.ORDERS o
    INNER JOIN #TargetOrders t ON t.ORDER_ID = o.ORDER_ID
    ORDER BY o.PLACED_AT DESC, o.ORDER_ID DESC;

    -- Result Set 2: Order Items
    SELECT 
        oi.ORDER_ITEM_ID AS OrderItemId,
        oi.ORDER_ID AS OrderId,
        oi.PRODUCT_ID AS ProductId,
        oi.PRODUCT_CODE AS ProductCode,
        oi.PRODUCT_NAME_EN AS ProductNameEn,
        oi.PRODUCT_NAME_AR AS ProductNameAr,
        ISNULL(img.PRIMARY_URL, '') AS ProductImage,
        oi.UNIT_DESCRIPTION AS UnitDescription,
        oi.REGULAR_UNIT_PRICE AS RegularUnitPrice,
        oi.SELLING_UNIT_PRICE AS SellingUnitPrice,
        oi.CUSTOMIZATION_UNIT_PRICE AS CustomizationUnitPrice,
        oi.QUANTITY AS Quantity,
        oi.LINE_SUBTOTAL AS LineSubtotal,
        oi.PRODUCT_DISCOUNT_AMOUNT AS ProductDiscountAmount,
        oi.LINE_TOTAL AS LineTotal,
        oi.SPECIAL_INSTRUCTIONS AS SpecialInstructions
    FROM dbo.ORDER_ITEMS oi
    INNER JOIN #TargetOrders t ON t.ORDER_ID = oi.ORDER_ID
    LEFT JOIN dbo.PRODUCT_IMAGES img ON img.PRODUCT_ID = oi.PRODUCT_ID
    ORDER BY oi.ORDER_ITEM_ID ASC;

    -- Result Set 3: Order Item Customizations
    SELECT 
        oic.ORDER_ITEM_CUSTOMIZATION_ID AS OrderItemCustomizationId,
        oic.ORDER_ITEM_ID AS OrderItemId,
        oic.CUSTOMIZATION_OPTION_ID AS CustomizationOptionId,
        oic.GROUP_NAME_EN AS GroupNameEn,
        oic.GROUP_NAME_AR AS GroupNameAr,
        oic.OPTION_NAME_EN AS OptionNameEn,
        oic.OPTION_NAME_AR AS OptionNameAr,
        oic.ADDITIONAL_PRICE AS AdditionalPrice
    FROM dbo.ORDER_ITEM_CUSTOMIZATIONS oic
    INNER JOIN dbo.ORDER_ITEMS oi ON oi.ORDER_ITEM_ID = oic.ORDER_ITEM_ID
    INNER JOIN #TargetOrders t ON t.ORDER_ID = oi.ORDER_ID
    ORDER BY oic.ORDER_ITEM_CUSTOMIZATION_ID ASC;

    -- Result Set 4: Order Status History
    SELECT 
        h.ORDER_STATUS_HISTORY_ID AS OrderStatusHistoryId,
        h.ORDER_ID AS OrderId,
        h.ORDER_STATUS AS OrderStatus,
        h.REMARKS AS Remarks,
        h.CREATED_AT AS CreatedAt
    FROM dbo.ORDER_STATUS_HISTORY h
    INNER JOIN #TargetOrders t ON t.ORDER_ID = h.ORDER_ID
    ORDER BY h.CREATED_AT ASC;

    DROP TABLE #TargetOrders;
END;
GO
