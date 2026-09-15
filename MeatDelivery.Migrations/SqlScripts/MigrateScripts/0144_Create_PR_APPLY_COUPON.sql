-- =============================================================================
-- STORED PROCEDURE: dbo.PR_APPLY_COUPON
-- Description: Validates coupon code rules against customer active cart and applies COUPON_ID.
-- Migration: 0144_Create_PR_APPLY_COUPON.sql
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_APPLY_COUPON
(
    @CUSTOMER_USER_ID BIGINT,
    @COUPON_CODE      VARCHAR(50)
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CART_ID BIGINT;
    DECLARE @COUPON_ID BIGINT;
    DECLARE @DISCOUNT_TYPE VARCHAR(20);
    DECLARE @DISCOUNT_VALUE DECIMAL(18, 2);
    DECLARE @MAX_DISCOUNT_AMOUNT DECIMAL(18, 2);
    DECLARE @MINIMUM_ORDER_AMOUNT DECIMAL(18, 2);
    DECLARE @VALID_FROM DATETIME2;
    DECLARE @VALID_TO DATETIME2;
    DECLARE @USAGE_LIMIT_TOTAL INT;
    DECLARE @USAGE_LIMIT_PER_USER INT;
    DECLARE @TIMES_USED INT;
    DECLARE @COUPON_STATUS VARCHAR(20);
    DECLARE @IS_DELETED BIT;
    DECLARE @COUPON_NAME NVARCHAR(150);

    -- 1. Locate Customer Active Cart
    SELECT @CART_ID = CART_ID
    FROM dbo.CARTS
    WHERE CUSTOMER_USER_ID = @CUSTOMER_USER_ID
      AND CART_STATUS = 'ACTIVE';

    IF @CART_ID IS NULL
    BEGIN
        RAISERROR('Active cart not found for customer.', 16, 1);
        RETURN;
    END

    -- 2. Locate Coupon Record
    SELECT 
        @COUPON_ID = COUPON_ID,
        @COUPON_NAME = COUPON_DESC,
        @DISCOUNT_TYPE = DISCOUNT_TYPE,
        @DISCOUNT_VALUE = DISCOUNT_VALUE,
        @MAX_DISCOUNT_AMOUNT = MAX_DISCOUNT_AMOUNT,
        @MINIMUM_ORDER_AMOUNT = MINIMUM_ORDER_AMOUNT,
        @VALID_FROM = VALID_FROM,
        @VALID_TO = VALID_TO,
        @USAGE_LIMIT_TOTAL = USAGE_LIMIT_TOTAL,
        @USAGE_LIMIT_PER_USER = USAGE_LIMIT_PER_USER,
        @COUPON_STATUS = COUPON_STATUS,
        @IS_DELETED = IS_DELETED
    FROM dbo.COUPONS
    WHERE UPPER(COUPON_CODE) = UPPER(@COUPON_CODE);

    IF @COUPON_ID IS NULL OR @IS_DELETED = 1
    BEGIN
        RAISERROR('Invalid or non-existent promo code.', 16, 1);
        RETURN;
    END

    -- Calculate total times used
    SELECT @TIMES_USED = COUNT(1)
    FROM dbo.COUPON_USAGES
    WHERE COUPON_ID = @COUPON_ID AND USAGE_STATUS = 'USED';

    -- 3. Check Coupon Status
    IF UPPER(@COUPON_STATUS) <> 'ACTIVE'
    BEGIN
        RAISERROR('This coupon code is currently inactive.', 16, 1);
        RETURN;
    END

    -- 4. Check Date Validity
    DECLARE @NOW DATETIME2 = SYSUTCDATETIME();
    IF (@VALID_FROM IS NOT NULL AND @NOW < @VALID_FROM) OR (@VALID_TO IS NOT NULL AND @NOW > @VALID_TO)
    BEGIN
        RAISERROR('This promo code is expired or not yet valid.', 16, 1);
        RETURN;
    END

    -- 5. Check Global Usage Limit
    IF @USAGE_LIMIT_TOTAL IS NOT NULL AND @TIMES_USED >= @USAGE_LIMIT_TOTAL
    BEGIN
        RAISERROR('This promo code has reached its maximum global usage limit.', 16, 1);
        RETURN;
    END

    -- 6. Check Per-User Usage Limit
    IF @USAGE_LIMIT_PER_USER IS NOT NULL
    BEGIN
        DECLARE @USER_USAGE_COUNT INT = 0;
        SELECT @USER_USAGE_COUNT = COUNT(1)
        FROM dbo.COUPON_USAGES
        WHERE CUSTOMER_USER_ID = @CUSTOMER_USER_ID
          AND COUPON_ID = @COUPON_ID;

        IF @USER_USAGE_COUNT >= @USAGE_LIMIT_PER_USER
        BEGIN
            RAISERROR('You have reached the maximum allowed usage limit for this coupon code.', 16, 1);
            RETURN;
        END
    END

    -- 7. Check Minimum Order Subtotal Requirement
    DECLARE @CART_SUBTOTAL DECIMAL(18, 2) = 0.00;

    SELECT @CART_SUBTOTAL = ISNULL(SUM(ci.QUANTITY * ISNULL(pr.PRICE, 0)), 0.00)
    FROM dbo.CART_ITEMS ci
    LEFT JOIN dbo.PRODUCT_PRICES pr ON pr.PRODUCT_ID = ci.PRODUCT_ID AND pr.IS_ACTIVE = 1
    WHERE ci.CART_ID = @CART_ID
      AND ci.ITEM_STATUS = 'ACTIVE';

    IF @CART_SUBTOTAL < @MINIMUM_ORDER_AMOUNT
    BEGIN
        DECLARE @MIN_ERR NVARCHAR(250) = CONCAT('Minimum cart amount for coupon ', UPPER(@COUPON_CODE), ' is ', FORMAT(@MINIMUM_ORDER_AMOUNT, '0.00'), ' AED.');
        RAISERROR(@MIN_ERR, 16, 1);
        RETURN;
    END

    -- 8. Apply Coupon to Active Cart
    UPDATE dbo.CARTS
    SET COUPON_ID = @COUPON_ID,
        UPDATED_AT = SYSUTCDATETIME()
    WHERE CART_ID = @CART_ID;

    -- 9. Return Applied Coupon Summary
    SELECT 
        c.CART_ID,
        cp.COUPON_ID,
        cp.COUPON_CODE,
        cp.COUPON_DESC AS COUPON_NAME,
        cp.DISCOUNT_TYPE,
        cp.DISCOUNT_VALUE,
        cp.MAX_DISCOUNT_AMOUNT,
        cp.MINIMUM_ORDER_AMOUNT
    FROM dbo.CARTS c
    INNER JOIN dbo.COUPONS cp ON cp.COUPON_ID = c.COUPON_ID
    WHERE c.CART_ID = @CART_ID;
END;
GO
