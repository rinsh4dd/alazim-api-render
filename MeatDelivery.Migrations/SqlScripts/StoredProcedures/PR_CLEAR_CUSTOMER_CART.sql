CREATE OR ALTER PROCEDURE dbo.PR_CLEAR_CUSTOMER_CART
    @CUSTOMER_USER_ID BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    BEGIN TRY
        IF @CUSTOMER_USER_ID IS NULL OR @CUSTOMER_USER_ID <= 0
        BEGIN
            RAISERROR('Valid CustomerUserId is required.', 16, 1);
            RETURN;
        END;

        DECLARE @CART_ID BIGINT;

        SELECT TOP 1 
            @CART_ID = CART_ID
        FROM dbo.CARTS
        WHERE CUSTOMER_USER_ID = @CUSTOMER_USER_ID
          AND CART_STATUS = 'ACTIVE';

        IF @CART_ID IS NOT NULL
        BEGIN
            DELETE cic
            FROM dbo.CART_ITEM_CUSTOMIZATIONS cic
            INNER JOIN dbo.CART_ITEMS ci ON cic.CART_ITEM_ID = ci.CART_ITEM_ID
            WHERE ci.CART_ID = @CART_ID;

            DELETE FROM dbo.CART_ITEMS
            WHERE CART_ID = @CART_ID;

            UPDATE dbo.CARTS
            SET UPDATED_AT = SYSUTCDATETIME()
            WHERE CART_ID = @CART_ID;
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
