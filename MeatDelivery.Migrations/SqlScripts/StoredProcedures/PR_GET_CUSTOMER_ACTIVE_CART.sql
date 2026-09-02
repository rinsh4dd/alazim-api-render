-- =============================================================================
-- STORED PROCEDURE: dbo.PR_GET_CUSTOMER_ACTIVE_CART
-- Description: Retrieves active cart header, item list, and item customization options for dynamic cart calculations.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_GET_CUSTOMER_ACTIVE_CART
(
    @CUSTOMER_USER_ID BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Cart Header
    SELECT 
        c.CART_ID,
        c.CUSTOMER_USER_ID,
        c.CART_STATUS,
        c.COUPON_ID,
        c.CREATED_AT
    FROM dbo.CARTS c
    WHERE c.CUSTOMER_USER_ID = @CUSTOMER_USER_ID
      AND c.CART_STATUS = 'ACTIVE';

    -- 2. Cart Items
    SELECT 
        ci.CART_ITEM_ID,
        ci.CART_ID,
        ci.PRODUCT_ID,
        p.PRODUCT_NAME_EN,
        p.PRODUCT_NAME_AR,
        img.PRIMARY_URL AS PRODUCT_IMAGE,
        u.UNIT_DESCRIPTION,
        pr.PRICE AS BASE_PRICE,
        ci.QUANTITY,
        ci.CUSTOM_DATA,
        ci.SPECIAL_INSTRUCTIONS,
        ci.ITEM_STATUS
    FROM dbo.CART_ITEMS ci
    INNER JOIN dbo.CARTS c ON c.CART_ID = ci.CART_ID
    INNER JOIN dbo.PRODUCTS p ON p.PRODUCT_ID = ci.PRODUCT_ID
    LEFT JOIN dbo.MEASUREMENT_UNITS u ON u.UNIT_ID = p.UNIT_ID
    LEFT JOIN dbo.PRODUCT_PRICES pr ON pr.PRODUCT_ID = p.PRODUCT_ID AND pr.IS_ACTIVE = 1
    LEFT JOIN dbo.PRODUCT_IMAGES img ON img.PRODUCT_ID = p.PRODUCT_ID
    WHERE c.CUSTOMER_USER_ID = @CUSTOMER_USER_ID
      AND c.CART_STATUS = 'ACTIVE'
      AND ci.ITEM_STATUS = 'ACTIVE';

    -- 3. Cart Item Customizations
    SELECT 
        cic.CART_ITEM_ID,
        co.CUSTOMIZATION_OPTION_ID,
        cg.CUSTOMIZATION_GROUP_ID,
        cg.GROUP_NAME_EN,
        cg.GROUP_NAME_AR,
        co.OPTION_CODE,
        co.OPTION_NAME_EN,
        co.OPTION_NAME_AR,
        cg.PRICING_TYPE,
        ISNULL(co.ADDITIONAL_PRICE, 0) AS ADDITIONAL_PRICE
    FROM dbo.CART_ITEM_CUSTOMIZATIONS cic
    INNER JOIN dbo.CART_ITEMS ci ON ci.CART_ITEM_ID = cic.CART_ITEM_ID
    INNER JOIN dbo.CARTS c ON c.CART_ID = ci.CART_ID
    INNER JOIN dbo.CUSTOMIZATION_OPTIONS co ON co.CUSTOMIZATION_OPTION_ID = cic.CUSTOMIZATION_OPTION_ID
    INNER JOIN dbo.CUSTOMIZATION_GROUPS cg ON cg.CUSTOMIZATION_GROUP_ID = co.CUSTOMIZATION_GROUP_ID
    WHERE c.CUSTOMER_USER_ID = @CUSTOMER_USER_ID
      AND c.CART_STATUS = 'ACTIVE'
      AND ci.ITEM_STATUS = 'ACTIVE';
END;
GO
