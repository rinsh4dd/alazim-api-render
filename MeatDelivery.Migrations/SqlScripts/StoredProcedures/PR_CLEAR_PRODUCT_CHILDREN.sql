-- =============================================================================
-- STORED PROCEDURE: dbo.PR_CLEAR_PRODUCT_CHILDREN
-- Description: Clears existing weight options, prices, or images for a product.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_CLEAR_PRODUCT_CHILDREN
    @PRODUCT_ID     BIGINT,
    @CLEAR_WEIGHTS  BIT = 1,
    @CLEAR_IMAGES   BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF ISNULL(@CLEAR_WEIGHTS, 1) = 1
    BEGIN
        DELETE FROM dbo.PRODUCT_PRICES WHERE PRODUCT_ID = @PRODUCT_ID;
        DELETE FROM dbo.PRODUCT_WEIGHT_OPTIONS WHERE PRODUCT_ID = @PRODUCT_ID;
    END;

    IF ISNULL(@CLEAR_IMAGES, 1) = 1
    BEGIN
        DELETE FROM dbo.PRODUCT_IMAGES WHERE PRODUCT_ID = @PRODUCT_ID;
    END;
END;
GO
