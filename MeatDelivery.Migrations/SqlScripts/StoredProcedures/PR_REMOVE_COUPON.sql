-- =============================================================================
-- STORED PROCEDURE: dbo.PR_REMOVE_COUPON
-- Description: Removes currently applied COUPON_ID from customer active cart.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_REMOVE_COUPON
(
    @CUSTOMER_USER_ID BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CART_ID BIGINT;

    SELECT @CART_ID = CART_ID
    FROM dbo.CARTS
    WHERE CUSTOMER_USER_ID = @CUSTOMER_USER_ID
      AND CART_STATUS = 'ACTIVE';

    IF @CART_ID IS NULL
    BEGIN
        RAISERROR('Active cart not found for customer.', 16, 1);
        RETURN;
    END

    UPDATE dbo.CARTS
    SET COUPON_ID = NULL,
        UPDATED_AT = SYSUTCDATETIME()
    WHERE CART_ID = @CART_ID;

    SELECT @CART_ID AS CART_ID;
END;
GO
