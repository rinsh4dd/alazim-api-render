-- =============================================================================
-- STORED PROCEDURE: dbo.PR_GET_CUSTOMER_WISHLIST
-- Description: Retrieves lightweight paginated wishlist products for a customer.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_GET_CUSTOMER_WISHLIST
(
    @CUSTOMER_USER_ID   BIGINT,
    @PAGE_NUMBER        INT = 1,
    @PAGE_SIZE          INT = 10
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @PAGE_NUMBER = ISNULL(@PAGE_NUMBER, 1);
    IF @PAGE_NUMBER < 1 SET @PAGE_NUMBER = 1;

    SET @PAGE_SIZE = ISNULL(@PAGE_SIZE, 10);
    IF @PAGE_SIZE < 1 SET @PAGE_SIZE = 10;
    IF @PAGE_SIZE > 100 SET @PAGE_SIZE = 100;

    DECLARE @OFFSET INT = (@PAGE_NUMBER - 1) * @PAGE_SIZE;

    DECLARE @WISHLIST_ID BIGINT;
    SELECT @WISHLIST_ID = WISHLIST_ID FROM dbo.WISHLISTS WHERE CUSTOMER_USER_ID = @CUSTOMER_USER_ID;

    SELECT COUNT(1) AS TotalRecords
    FROM dbo.WISHLIST_ITEMS wi
    INNER JOIN dbo.PRODUCTS p ON wi.PRODUCT_ID = p.PRODUCT_ID
    WHERE wi.WISHLIST_ID = @WISHLIST_ID AND p.IS_DELETED = 0 AND p.IS_ACTIVE = 1;

    SELECT
        p.PRODUCT_ID AS ProductId,
        p.PRODUCT_NAME_EN AS ProductNameEn,
        p.PRODUCT_NAME_AR AS ProductNameAr,
        p.DESCRIPTION_EN AS DescriptionEn,
        p.DESCRIPTION_AR AS DescriptionAr,
        pr.PRICE AS Price,
        CAST(pr.PRICE - (pr.PRICE * (p.DISCOUNT_PERCENTAGE / 100.0)) AS DECIMAL(18,2)) AS SellingPrice,
        p.DISCOUNT_PERCENTAGE AS DiscountPercentage,
        img.PRIMARY_URL AS PrimaryUrl,
        u.UNIT AS UnitCode,
        wi.ADDED_AT AS AddedAt
    FROM dbo.WISHLIST_ITEMS wi
    INNER JOIN dbo.PRODUCTS p ON wi.PRODUCT_ID = p.PRODUCT_ID
    INNER JOIN dbo.MEASUREMENT_UNITS u ON p.UNIT_ID = u.UNIT_ID
    LEFT JOIN dbo.PRODUCT_PRICES pr ON p.PRODUCT_ID = pr.PRODUCT_ID AND pr.IS_ACTIVE = 1
    LEFT JOIN dbo.PRODUCT_IMAGES img ON p.PRODUCT_ID = img.PRODUCT_ID
    WHERE wi.WISHLIST_ID = @WISHLIST_ID AND p.IS_DELETED = 0 AND p.IS_ACTIVE = 1
    ORDER BY wi.ADDED_AT DESC
    OFFSET @OFFSET ROWS
    FETCH NEXT @PAGE_SIZE ROWS ONLY;
END;
GO
