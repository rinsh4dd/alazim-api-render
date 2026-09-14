IF OBJECT_ID('dbo.PR_GET_ORDER_INVOICE', 'P') IS NOT NULL
    DROP PROCEDURE dbo.PR_GET_ORDER_INVOICE;
GO

CREATE PROCEDURE dbo.PR_GET_ORDER_INVOICE
    @ORDER_ID BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Order Master & Customer & Delivery Address & Company Config Details
    SELECT
        'INV-' + o.DOC_NO AS InvoiceNo,
        ISNULL(o.PLACED_AT, o.CREATED_AT) AS InvoiceDate,
        cc.COMPANY_NAME_EN AS CompanyNameEn,
        cc.COMPANY_NAME_AR AS CompanyNameAr,
        cc.ADDRESS_LINE_1 AS CompanyAddress,
        cc.CONTACT_NUMBER AS CompanyPhone,
        cc.EMAIL AS CompanyEmail,
        o.ORDER_ID AS OrderId,
        o.DOC_NO AS OrderDocNo,
        o.PLACED_AT AS PlacedAt,
        o.ORDER_STATUS AS OrderStatus,
        o.CUSTOMER_USER_ID AS CustomerUserId,
        ISNULL(c.FIRST_NAME + ' ' + ISNULL(c.LAST_NAME, ''), 'Valued Customer') AS CustomerName,
        ISNULL(c.PHONE_NUMBER, o.DELIVERY_CONTACT_NUMBER) AS CustomerPhone,
        c.EMAIL AS CustomerEmail,
        o.CURRENCY_CODE AS CurrencyCode,
        o.SUBTOTAL AS Subtotal,
        o.PRODUCT_DISCOUNT_TOTAL AS ProductDiscountTotal,
        o.COUPON_ID AS CouponId,
        o.COUPON_DISCOUNT AS CouponDiscount,
        o.DELIVERY_CHARGE AS DeliveryCharge,
        o.TOTAL_AMOUNT AS TotalAmount,
        o.PAYMENT_METHOD AS PaymentMethod,
        o.PAYMENT_STATUS AS PaymentStatus,
        -- Delivery Address
        o.ADDRESS_ID AS AddressId,
        o.DELIVERY_ADDRESS_TYPE AS AddressType,
        o.DELIVERY_CONTACT_NUMBER AS ContactNumber,
        o.DELIVERY_BUILDING_NAME AS BuildingName,
        o.DELIVERY_VILLA_OR_FLAT_NO AS VillaOrFlatNo,
        o.DELIVERY_STREET AS Street,
        o.DELIVERY_AREA AS Area,
        o.DELIVERY_LANDMARK AS Landmark,
        o.DELIVERY_CITY AS City,
        o.DELIVERY_EMIRATE AS Emirate,
        o.DELIVERY_POSTAL_CODE AS PostalCode,
        o.DELIVERY_LATITUDE AS Latitude,
        o.DELIVERY_LONGITUDE AS Longitude,
        -- Delivery Schedule
        CONVERT(VARCHAR(10), o.DELIVERY_DATE, 120) AS DeliveryDate,
        CONVERT(VARCHAR(8), o.DELIVERY_SLOT_START_TIME, 108) AS StartTime,
        CONVERT(VARCHAR(8), o.DELIVERY_SLOT_END_TIME, 108) AS EndTime
    FROM dbo.ORDERS o
    LEFT JOIN dbo.CUSTOMER_USERS c ON o.CUSTOMER_USER_ID = c.CUSTOMER_USER_ID
    OUTER APPLY (
        SELECT TOP 1 * FROM dbo.COMPANY_CONFIG WHERE IS_ACTIVE = 1 ORDER BY COMPANY_CONFIG_ID DESC
    ) cc
    WHERE o.ORDER_ID = @ORDER_ID;

    -- 2. Order Items
    SELECT
        oi.ORDER_ITEM_ID AS OrderItemId,
        oi.PRODUCT_ID AS ProductId,
        p.DOC_NO AS ProductCode,
        p.PRODUCT_NAME_EN AS ProductNameEn,
        p.PRODUCT_NAME_AR AS ProductNameAr,
        u.UNIT_DESCRIPTION AS UnitDescription,
        oi.REGULAR_UNIT_PRICE AS RegularUnitPrice,
        oi.SELLING_UNIT_PRICE AS SellingUnitPrice,
        oi.CUSTOMIZATION_UNIT_PRICE AS CustomizationUnitPrice,
        oi.QUANTITY AS Quantity,
        oi.LINE_SUBTOTAL AS LineSubtotal,
        oi.PRODUCT_DISCOUNT_AMOUNT AS ProductDiscountAmount,
        oi.LINE_TOTAL AS LineTotal,
        oi.SPECIAL_INSTRUCTIONS AS SpecialInstructions
    FROM dbo.ORDER_ITEMS oi
    INNER JOIN dbo.PRODUCTS p ON oi.PRODUCT_ID = p.PRODUCT_ID
    LEFT JOIN dbo.MEASUREMENT_UNITS u ON p.UNIT_ID = u.UNIT_ID
    WHERE oi.ORDER_ID = @ORDER_ID;

    -- 3. Item Customizations
    SELECT
        oic.ORDER_ITEM_ID AS OrderItemId,
        oic.CUSTOMIZATION_OPTION_ID AS CustomizationOptionId,
        cg.GROUP_NAME_EN AS GroupNameEn,
        cg.GROUP_NAME_AR AS GroupNameAr,
        co.OPTION_NAME_EN AS OptionNameEn,
        co.OPTION_NAME_AR AS OptionNameAr,
        oic.ADDITIONAL_PRICE AS AdditionalPrice
    FROM dbo.ORDER_ITEM_CUSTOMIZATIONS oic
    INNER JOIN dbo.ORDER_ITEMS oi ON oic.ORDER_ITEM_ID = oi.ORDER_ITEM_ID
    INNER JOIN dbo.CUSTOMIZATION_OPTIONS co ON oic.CUSTOMIZATION_OPTION_ID = co.CUSTOMIZATION_OPTION_ID
    INNER JOIN dbo.CUSTOMIZATION_GROUPS cg ON co.CUSTOMIZATION_GROUP_ID = cg.CUSTOMIZATION_GROUP_ID
    WHERE oi.ORDER_ID = @ORDER_ID;
END;
GO
