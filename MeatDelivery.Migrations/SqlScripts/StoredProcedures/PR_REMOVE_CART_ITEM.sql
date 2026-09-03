CREATE OR ALTER PROCEDURE dbo.PR_REMOVE_CART_ITEM
    @CUSTOMER_USER_ID BIGINT,
    @CART_ITEM_ID BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- 1. Validate Customer
        IF @CUSTOMER_USER_ID IS NULL OR @CUSTOMER_USER_ID <= 0
        BEGIN
            RAISERROR('Valid CustomerUserId is required.', 16, 1);
            RETURN;
        END;

        -- 2. Validate Cart Item exists and belongs to active cart of customer
        DECLARE @CART_ID BIGINT, @PRODUCT_ID BIGINT, @PRODUCT_NAME_EN NVARCHAR(255), @PRODUCT_NAME_AR NVARCHAR(255);

        SELECT 
            @CART_ID = ci.CART_ID,
            @PRODUCT_ID = p.PRODUCT_ID,
            @PRODUCT_NAME_EN = p.PRODUCT_NAME_EN,
            @PRODUCT_NAME_AR = p.PRODUCT_NAME_AR
        FROM dbo.CART_ITEMS ci
        INNER JOIN dbo.CARTS c ON ci.CART_ID = c.CART_ID
        INNER JOIN dbo.PRODUCTS p ON ci.PRODUCT_ID = p.PRODUCT_ID
        WHERE ci.CART_ITEM_ID = @CART_ITEM_ID
          AND c.CUSTOMER_USER_ID = @CUSTOMER_USER_ID
          AND c.CART_STATUS = 'ACTIVE';

        IF @CART_ID IS NULL
        BEGIN
            RAISERROR('Cart item not found or does not belong to active customer cart.', 16, 1);
            RETURN;
        END;

        -- 3. Delete Customizations & Cart Item
        DELETE FROM dbo.CART_ITEM_CUSTOMIZATIONS
        WHERE CART_ITEM_ID = @CART_ITEM_ID;

        DELETE FROM dbo.CART_ITEMS
        WHERE CART_ITEM_ID = @CART_ITEM_ID;

        -- 4. Update Cart timestamp
        UPDATE dbo.CARTS
        SET UPDATED_AT = SYSUTCDATETIME()
        WHERE CART_ID = @CART_ID;

        COMMIT TRANSACTION;

        SELECT 
            @CART_ITEM_ID AS CartItemId,
            @PRODUCT_ID AS ProductId,
            @PRODUCT_NAME_EN AS ProductNameEn,
            @PRODUCT_NAME_AR AS ProductNameAr;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
