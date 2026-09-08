-- =============================================================================
-- STORED PROCEDURE: dbo.PR_PLACE_ORDER
-- Description: Places a customer order by converting active cart set-based.
-- Generates DOC_NO via PR_GET_NEXT_DOC_NO ('ORD1'), copies address details from
-- dbo.CUSTOMER_ADDRESSES and items/customizations directly from active cart tables.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_PLACE_ORDER
(
    @CUSTOMER_USER_ID           BIGINT,
    @ADDRESS_ID                 BIGINT,
    @DELIVERY_DATE              DATE,
    @DELIVERY_SLOT_START_TIME   TIME,
    @DELIVERY_SLOT_END_TIME     TIME,
    @PAYMENT_METHOD             VARCHAR(20)     = 'COD',
    @DELIVERY_INSTRUCTIONS      NVARCHAR(500)   = NULL,
    @ORDER_ID                   BIGINT          OUTPUT,
    @DOC_NO                     VARCHAR(50)     OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Validate Customer User
    IF @CUSTOMER_USER_ID IS NULL OR @CUSTOMER_USER_ID <= 0
    BEGIN
        RAISERROR('Valid CustomerUserId is required.', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.CUSTOMER_USERS WHERE USER_ID = @CUSTOMER_USER_ID)
    BEGIN
        RAISERROR('Customer user not found.', 16, 1);
        RETURN;
    END;

    -- Validate Address
    IF @ADDRESS_ID IS NULL OR @ADDRESS_ID <= 0
    BEGIN
        RAISERROR('Valid AddressId is required.', 16, 1);
        RETURN;
    END;

    DECLARE
        @ContactNumber VARCHAR(30),
        @AddressType VARCHAR(20),
        @BuildingName NVARCHAR(150),
        @VillaOrFlatNo NVARCHAR(50),
        @Street NVARCHAR(200),
        @Area NVARCHAR(150),
        @City NVARCHAR(100),
        @Landmark NVARCHAR(250),
        @PostalCode VARCHAR(20),
        @Emirate NVARCHAR(100),
        @Latitude DECIMAL(10, 7),
        @Longitude DECIMAL(10, 7),
        @CART_ID BIGINT = NULL,
        @Subtotal DECIMAL(18, 2) = 0.00,
        @DeliveryCharge DECIMAL(18, 2) = 0.00,
        @VatAmount DECIMAL(18, 2) = 0.00,
        @ProductDiscountTotal DECIMAL(18, 2) = 0.00,
        @CouponDiscount DECIMAL(18, 2) = 0.00,
        @TotalAmount DECIMAL(18, 2) = 0.00;

    SELECT TOP 1
        @ContactNumber = ISNULL(CONTACT_NUMBER, ''),
        @AddressType = ADDRESS_TYPE,
        @BuildingName = BUILDING_NAME,
        @VillaOrFlatNo = ISNULL(VILLA_OR_FLAT_NO, ''),
        @Street = ISNULL(STREET, ''),
        @Area = ISNULL(AREA, ''),
        @City = ISNULL(CITY, ''),
        @Landmark = LANDMARK,
        @PostalCode = POSTAL_CODE,
        @Emirate =EMIRATE,
        @Latitude = LATITUDE,
        @Longitude = LONGITUDE
    FROM dbo.CUSTOMER_ADDRESSES
    WHERE ADDRESS_ID = @ADDRESS_ID AND CUSTOMER_USER_ID = @CUSTOMER_USER_ID AND IS_ACTIVE = 1;

    IF @ContactNumber IS NULL
    BEGIN
        RAISERROR('Selected delivery address not found or inactive.', 16, 1);
        RETURN;
    END;

    -- Find Active Cart
    SELECT TOP 1 @CART_ID = CART_ID
    FROM dbo.CARTS
    WHERE CUSTOMER_USER_ID = @CUSTOMER_USER_ID AND CART_STATUS = 'ACTIVE';

    IF @CART_ID IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.CART_ITEMS WHERE CART_ID = @CART_ID AND ITEM_STATUS = 'ACTIVE')
    BEGIN
        RAISERROR('Active cart is empty. Cannot place order.', 16, 1);
        RETURN;
    END;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- 1. Generate Next DOC_NO for DOCTYPE 'ORD1'
        EXEC dbo.PR_GET_NEXT_DOC_NO
            @DOCTYPE = 'ORD1',
            @DOC_NO = @DOC_NO OUTPUT;

        IF @DOC_NO IS NULL OR LTRIM(RTRIM(@DOC_NO)) = ''
        BEGIN
            RAISERROR('Failed to generate document number for order.', 16, 1);
            RETURN;
        END;

        -- 2. Calculate Subtotal and Total from Active Cart Items & Customizations
        SELECT @Subtotal = ISNULL(SUM(
            (ISNULL(pr.PRICE, 0.00) + ISNULL(cust_sum.CustomizationUnitPrice, 0.00)) * ci.QUANTITY
        ), 0.00)
        FROM dbo.CART_ITEMS ci
        INNER JOIN dbo.PRODUCTS p ON p.PRODUCT_ID = ci.PRODUCT_ID
        LEFT JOIN dbo.PRODUCT_PRICES pr ON pr.PRODUCT_ID = p.PRODUCT_ID AND pr.IS_ACTIVE = 1
        LEFT JOIN (
            SELECT 
                cic.CART_ITEM_ID,
                SUM(ISNULL(co.PRICING_VALUE, 0.00)) AS CustomizationUnitPrice
            FROM dbo.CART_ITEM_CUSTOMIZATIONS cic
            INNER JOIN dbo.CUSTOMIZATION_OPTIONS co ON co.CUSTOMIZATION_OPTION_ID = cic.CUSTOMIZATION_OPTION_ID
            GROUP BY cic.CART_ITEM_ID
        ) cust_sum ON cust_sum.CART_ITEM_ID = ci.CART_ITEM_ID
        WHERE ci.CART_ID = @CART_ID AND ci.ITEM_STATUS = 'ACTIVE';

        SET @TotalAmount = @Subtotal - @CouponDiscount + @DeliveryCharge;

        -- 3. Insert Header into dbo.ORDERS
        INSERT INTO dbo.ORDERS
        (
            DOCTYPE, DOC_NO, CUSTOMER_USER_ID, CART_ID, ADDRESS_ID,
            DELIVERY_CONTACT_NUMBER, DELIVERY_ADDRESS_TYPE, DELIVERY_BUILDING_NAME,
            DELIVERY_VILLA_OR_FLAT_NO, DELIVERY_STREET, DELIVERY_AREA, DELIVERY_CITY,
            DELIVERY_LANDMARK, DELIVERY_POSTAL_CODE, DELIVERY_EMIRATE,
            DELIVERY_LATITUDE, DELIVERY_LONGITUDE, DELIVERY_INSTRUCTIONS,
            DELIVERY_DATE, DELIVERY_SLOT_START_TIME, DELIVERY_SLOT_END_TIME,
            ORDER_STATUS, PAYMENT_METHOD, PAYMENT_STATUS, CURRENCY_CODE,
            SUBTOTAL, PRODUCT_DISCOUNT_TOTAL, COUPON_ID, COUPON_DISCOUNT,
            DELIVERY_CHARGE, VAT_AMOUNT, TOTAL_AMOUNT, PLACED_AT, CREATED_AT
        )
        VALUES
        (
            'ORD1', @DOC_NO, @CUSTOMER_USER_ID, @CART_ID, @ADDRESS_ID,
            @ContactNumber, @AddressType, @BuildingName,
            @VillaOrFlatNo, @Street, @Area, @City,
            @Landmark, @PostalCode, @Emirate,
            @Latitude, @Longitude, @DELIVERY_INSTRUCTIONS,
            @DELIVERY_DATE, @DELIVERY_SLOT_START_TIME, @DELIVERY_SLOT_END_TIME,
            'PLACED', @PAYMENT_METHOD, 'PENDING', 'AED',
            @Subtotal, @ProductDiscountTotal, NULL, @CouponDiscount,
            @DeliveryCharge, @VatAmount, @TotalAmount, SYSUTCDATETIME(), SYSUTCDATETIME()
        );

        SET @ORDER_ID = SCOPE_IDENTITY();

        -- 4. Copy Cart Items into dbo.ORDER_ITEMS Set-Based using MERGE
        DECLARE @ItemMap TABLE
        (
            OrderItemId BIGINT NOT NULL,
            CartItemId BIGINT NOT NULL
        );

        MERGE INTO dbo.ORDER_ITEMS AS target
        USING (
            SELECT 
                ci.CART_ITEM_ID,
                ci.PRODUCT_ID,
                ISNULL(NULLIF(p.DOC_NO, ''), '') AS PRODUCT_CODE,
                p.PRODUCT_NAME_EN,
                p.PRODUCT_NAME_AR,
                ISNULL(u.UNIT_DESCRIPTION, 'Kilogram') AS UNIT_DESCRIPTION,
                ISNULL(pr.PRICE, 0.00) AS REGULAR_UNIT_PRICE,
                ISNULL(pr.PRICE, 0.00) AS SELLING_UNIT_PRICE,
                ISNULL(cust_sum.CustomizationUnitPrice, 0.00) AS CUSTOMIZATION_UNIT_PRICE,
                ci.QUANTITY,
                (ISNULL(pr.PRICE, 0.00) * ci.QUANTITY) AS LINE_SUBTOTAL,
                0.00 AS PRODUCT_DISCOUNT_AMOUNT,
                ((ISNULL(pr.PRICE, 0.00) + ISNULL(cust_sum.CustomizationUnitPrice, 0.00)) * ci.QUANTITY) AS LINE_TOTAL,
                ci.SPECIAL_INSTRUCTIONS
            FROM dbo.CART_ITEMS ci
            INNER JOIN dbo.PRODUCTS p ON p.PRODUCT_ID = ci.PRODUCT_ID
            LEFT JOIN dbo.MEASUREMENT_UNITS u ON u.UNIT_ID = p.UNIT_ID
            LEFT JOIN dbo.PRODUCT_PRICES pr ON pr.PRODUCT_ID = p.PRODUCT_ID AND pr.IS_ACTIVE = 1
            LEFT JOIN (
                SELECT 
                    cic.CART_ITEM_ID,
                    SUM(ISNULL(co.PRICING_VALUE, 0.00)) AS CustomizationUnitPrice
                FROM dbo.CART_ITEM_CUSTOMIZATIONS cic
                INNER JOIN dbo.CUSTOMIZATION_OPTIONS co ON co.CUSTOMIZATION_OPTION_ID = cic.CUSTOMIZATION_OPTION_ID
                GROUP BY cic.CART_ITEM_ID
            ) cust_sum ON cust_sum.CART_ITEM_ID = ci.CART_ITEM_ID
            WHERE ci.CART_ID = @CART_ID
              AND ci.ITEM_STATUS = 'ACTIVE'
        ) AS source
        ON (1 = 0)
        WHEN NOT MATCHED THEN
            INSERT
            (
                ORDER_ID, DOC_NO, PRODUCT_ID, PRODUCT_CODE, PRODUCT_NAME_EN, PRODUCT_NAME_AR,
                UNIT_DESCRIPTION, REGULAR_UNIT_PRICE, SELLING_UNIT_PRICE, CUSTOMIZATION_UNIT_PRICE,
                QUANTITY, LINE_SUBTOTAL, PRODUCT_DISCOUNT_AMOUNT, LINE_TOTAL, SPECIAL_INSTRUCTIONS, CREATED_AT
            )
            VALUES
            (
                @ORDER_ID, @DOC_NO, source.PRODUCT_ID, source.PRODUCT_CODE, source.PRODUCT_NAME_EN, source.PRODUCT_NAME_AR,
                source.UNIT_DESCRIPTION, source.REGULAR_UNIT_PRICE, source.SELLING_UNIT_PRICE, source.CUSTOMIZATION_UNIT_PRICE,
                source.QUANTITY, source.LINE_SUBTOTAL, source.PRODUCT_DISCOUNT_AMOUNT, source.LINE_TOTAL, source.SPECIAL_INSTRUCTIONS, SYSUTCDATETIME()
            )
        OUTPUT inserted.ORDER_ITEM_ID, source.CART_ITEM_ID INTO @ItemMap (OrderItemId, CartItemId);

        -- 5. Copy Customizations Set-Based
        INSERT INTO dbo.ORDER_ITEM_CUSTOMIZATIONS
        (
            ORDER_ITEM_ID, DOC_NO, CUSTOMIZATION_OPTION_ID,
            GROUP_NAME_EN, GROUP_NAME_AR, OPTION_NAME_EN, OPTION_NAME_AR, ADDITIONAL_PRICE, CREATED_AT
        )
        SELECT
            m.OrderItemId,
            @DOC_NO,
            co.CUSTOMIZATION_OPTION_ID,
            cg.GROUP_NAME_EN,
            cg.GROUP_NAME_AR,
            co.OPTION_NAME_EN,
            co.OPTION_NAME_AR,
            ISNULL(co.PRICING_VALUE, 0.00),
            SYSUTCDATETIME()
        FROM dbo.CART_ITEM_CUSTOMIZATIONS cic
        INNER JOIN @ItemMap m ON m.CartItemId = cic.CART_ITEM_ID
        INNER JOIN dbo.CUSTOMIZATION_OPTIONS co ON co.CUSTOMIZATION_OPTION_ID = cic.CUSTOMIZATION_OPTION_ID
        INNER JOIN dbo.CUSTOMIZATION_GROUPS cg ON cg.CUSTOMIZATION_GROUP_ID = co.CUSTOMIZATION_GROUP_ID;

        -- 6. Insert Order Status History
        INSERT INTO dbo.ORDER_STATUS_HISTORY
        (
            ORDER_ID, DOC_NO, ORDER_STATUS, REMARKS, CREATED_AT
        )
        VALUES
        (
            @ORDER_ID, @DOC_NO, 'PLACED', 'Order placed successfully by customer', SYSUTCDATETIME()
        );

        -- 7. Convert Customer Cart Status to 'CONVERTED'
        UPDATE dbo.CARTS
        SET CART_STATUS = 'CONVERTED', UPDATED_AT = SYSUTCDATETIME()
        WHERE CART_ID = @CART_ID;

        UPDATE dbo.CART_ITEMS
        SET ITEM_STATUS = 'ORDERED', UPDATED_AT = SYSUTCDATETIME()
        WHERE CART_ID = @CART_ID AND ITEM_STATUS = 'ACTIVE';

        COMMIT TRANSACTION;

        SELECT @ORDER_ID AS OrderId, @DOC_NO AS DocNo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ERRMSG NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ERRMSG, 16, 1);
        RETURN;
    END CATCH;
END;
GO
