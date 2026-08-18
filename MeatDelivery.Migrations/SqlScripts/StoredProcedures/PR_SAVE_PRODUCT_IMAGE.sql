-- =============================================================================
-- STORED PROCEDURE: dbo.PR_SAVE_PRODUCT_IMAGE
-- Description: Inserts a product gallery image.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_SAVE_PRODUCT_IMAGE
    @PRODUCT_ID     BIGINT,
    @IMAGE_URL      VARCHAR(500),
    @IS_PRIMARY     BIT = 0,
    @DISPLAY_ORDER  INT = 0,
    @IS_ACTIVE      BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.PRODUCT_IMAGES
    (
        PRODUCT_ID, IMAGE_URL, IS_PRIMARY, DISPLAY_ORDER, IS_ACTIVE, CREATED_AT
    )
    VALUES
    (
        @PRODUCT_ID, @IMAGE_URL, ISNULL(@IS_PRIMARY, 0), ISNULL(@DISPLAY_ORDER, 0), ISNULL(@IS_ACTIVE, 1), SYSUTCDATETIME()
    );

    SELECT SCOPE_IDENTITY() AS ProductImageId;
END;
GO
