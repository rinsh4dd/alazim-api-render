-- =============================================================================
-- STORED PROCEDURE: dbo.PR_UPDATE_PRODUCT_STATUS
-- Description: Toggles the active status (IS_ACTIVE) for a given product.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_UPDATE_PRODUCT_STATUS
    @PRODUCT_ID BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.PRODUCTS WHERE PRODUCT_ID = @PRODUCT_ID AND IS_DELETED = 0)
    BEGIN
        RAISERROR('Product not found.', 16, 1);
        RETURN;
    END

    UPDATE dbo.PRODUCTS
    SET IS_ACTIVE = CASE WHEN IS_ACTIVE = 1 THEN 0 ELSE 1 END,
        UPDATED_AT = SYSUTCDATETIME()
    WHERE PRODUCT_ID = @PRODUCT_ID AND IS_DELETED = 0;

    EXEC dbo.PR_GET_PRODUCTS @PRODUCT_ID = @PRODUCT_ID;
END;
GO
