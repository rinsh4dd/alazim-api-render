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
        DECLARE @CART_ID BIGINT;

        SELECT 
            @CART_ID = ci.CART_ID
        FROM dbo.CART_ITEMS ci
        INNER JOIN dbo.CARTS c ON ci.CART_ID = c.CART_ID
        WHERE ci.CART_ITEM_ID = @CART_ITEM_ID
          AND c.CUSTOMER_USER_ID = @CUSTOMER_USER_ID
          AND c.IS_ACTIVE = 1;

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

        -- 4. Recalculate Cart Totals
        DECLARE @NEW_SUBTOTAL DECIMAL(18, 2);

        SELECT @NEW_SUBTOTAL = ISNULL(SUM(TOTAL_PRICE), 0.00)
        FROM dbo.CART_ITEMS
        WHERE CART_ID = @CART_ID;

        UPDATE dbo.CARTS
        SET 
            SUBTOTAL_AMOUNT = @NEW_SUBTOTAL,
            NET_AMOUNT = @NEW_SUBTOTAL - DISCOUNT_AMOUNT,
            TOTAL_ITEMS = (SELECT ISNULL(SUM(QUANTITY), 0) FROM dbo.CART_ITEMS WHERE CART_ID = @CART_ID),
            UPDATED_AT = GETUTCDATE()
        WHERE CART_ID = @CART_ID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
