-- =============================================================================
-- MIGRATION SCRIPT: 0126_Create_PR_PLACE_ORDER_TVP.sql
-- Description: Updates PR_PLACE_ORDER Stored Procedure with TVP support.
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
    @SUBTOTAL                   DECIMAL(18, 2),
    @DELIVERY_CHARGE            DECIMAL(18, 2)  = 0.00,
    @COUPON_DISCOUNT            DECIMAL(18, 2)  = 0.00,
    @VAT_AMOUNT                 DECIMAL(18, 2)  = 0.00,
    @TOTAL_AMOUNT               DECIMAL(18, 2),
    @ITEMS                      dbo.TT_ORDER_ITEMS READONLY,
    @CUSTOMIZATIONS             dbo.TT_ORDER_ITEM_CUSTOMIZATIONS READONLY,
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
        @CART_ID BIGINT = NULL;

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
        @Emirate = ISNULL(EMIRATE, 'Dubai'),
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

        -- 2. Insert Header into dbo.ORDERS
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
            @SUBTOTAL, 0.00, NULL, ISNULL(@COUPON_DISCOUNT, 0.00),
            ISNULL(@DELIVERY_CHARGE, 0.00), ISNULL(@VAT_AMOUNT, 0.00), @TOTAL_AMOUNT, SYSUTCDATETIME(), SYSUTCDATETIME()
        );

        SET @ORDER_ID = SCOPE_IDENTITY();

        -- 3. Copy Items Set-Based using MERGE from TVP @ITEMS
        DECLARE @ItemMap TABLE
        (
            OrderItemId BIGINT NOT NULL,
            ItemTempId INT NOT NULL
        );

        MERGE INTO dbo.ORDER_ITEMS AS target
        USING @ITEMS AS source
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
                @ORDER_ID,
                @DOC_NO,
                source.ProductId,
                ISNULL(NULLIF(source.ProductCode, ''), (SELECT TOP 1 ISNULL(DOC_NO, '') FROM dbo.PRODUCTS WHERE PRODUCT_ID = source.ProductId)),
                source.ProductNameEn,
                source.ProductNameAr,
                ISNULL(source.UnitDescription, 'Kilogram'),
                source.RegularUnitPrice,
                source.SellingUnitPrice,
                ISNULL(source.CustomizationUnitPrice, 0.00),
                source.Quantity,
                source.LineSubtotal,
                ISNULL(source.ProductDiscountAmount, 0.00),
                source.LineTotal,
                source.SpecialInstructions,
                SYSUTCDATETIME()
            )
        OUTPUT inserted.ORDER_ITEM_ID, source.ItemTempId INTO @ItemMap (OrderItemId, ItemTempId);

        -- 4. Copy Customizations Set-Based from TVP @CUSTOMIZATIONS
        INSERT INTO dbo.ORDER_ITEM_CUSTOMIZATIONS
        (
            ORDER_ITEM_ID, DOC_NO, CUSTOMIZATION_OPTION_ID,
            GROUP_NAME_EN, GROUP_NAME_AR, OPTION_NAME_EN, OPTION_NAME_AR, ADDITIONAL_PRICE, CREATED_AT
        )
        SELECT
            m.OrderItemId,
            @DOC_NO,
            c.CustomizationOptionId,
            c.GroupNameEn,
            c.GroupNameAr,
            c.OptionNameEn,
            c.OptionNameAr,
            ISNULL(c.AdditionalPrice, 0.00),
            SYSUTCDATETIME()
        FROM @CUSTOMIZATIONS c
        INNER JOIN @ItemMap m ON m.ItemTempId = c.ItemTempId;

        -- 5. Insert Order Status History
        INSERT INTO dbo.ORDER_STATUS_HISTORY
        (
            ORDER_ID, DOC_NO, ORDER_STATUS, REMARKS, CREATED_AT
        )
        VALUES
        (
            @ORDER_ID, @DOC_NO, 'PLACED', 'Order placed successfully by customer', SYSUTCDATETIME()
        );

        -- 6. Convert Customer Cart Status to 'CONVERTED'
        IF @CART_ID IS NOT NULL
        BEGIN
            UPDATE dbo.CARTS
            SET CART_STATUS = 'CONVERTED', UPDATED_AT = SYSUTCDATETIME()
            WHERE CART_ID = @CART_ID;

            UPDATE dbo.CART_ITEMS
            SET ITEM_STATUS = 'ORDERED', UPDATED_AT = SYSUTCDATETIME()
            WHERE CART_ID = @CART_ID AND ITEM_STATUS = 'ACTIVE';
        END;

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
