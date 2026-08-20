-- =============================================================================
-- STORED PROCEDURE: dbo.PR_GET_FEATURED_PRODUCTS
-- Description: Retrieves all active, non-deleted featured products.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_GET_FEATURED_PRODUCTS
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.PRODUCT_ID AS ProductId,
        p.CATEGORY_ID AS CategoryId,
        c.CATEGORY_NAME_EN AS CategoryNameEn,
        c.CATEGORY_NAME_AR AS CategoryNameAr,
        p.DOC_NO AS DocNo,
        p.DOC_TYPE AS DocType,
        p.PRODUCT_NAME_EN AS ProductNameEn,
        p.PRODUCT_NAME_AR AS ProductNameAr,
        p.DESCRIPTION_EN AS DescriptionEn,
        p.DESCRIPTION_AR AS DescriptionAr,
        p.IS_CUSTOMIZABLE AS IsCustomizable,
        p.CUSTOMIZATION_TEMPLATE_ID AS CustomizationTemplateId,
        p.UNIT_ID AS UnitId,
        u.UNIT AS UnitCode,
        u.UNIT_DESCRIPTION AS UnitDescription,
        p.DISCOUNT_PERCENTAGE AS DiscountPercentage,
        p.STOCK_COUNT AS StockCount,
        pr.PRICE AS Price,
        CAST(pr.PRICE - (pr.PRICE * (p.DISCOUNT_PERCENTAGE / 100.0)) AS DECIMAL(18,2)) AS SellingPrice,
        img.PRIMARY_URL AS PrimaryUrl,
        img.SECONDARY_URL AS SecondaryUrl,
        img.TERTIARY_URL AS TertiaryUrl,
        p.IS_FEATURED AS IsFeatured,
        p.IS_PREORDERABLE AS IsPreorderable,
        p.IS_ACTIVE AS IsActive,
        p.IS_DELETED AS IsDeleted,
        p.DELETED_AT AS DeletedAt,
        p.IS_NEW_ARRIVAL AS IsNewArrival,
        p.CREATED_AT AS CreatedAt,
        p.UPDATED_AT AS UpdatedAt
    FROM dbo.PRODUCTS p
    INNER JOIN dbo.CATEGORIES c ON p.CATEGORY_ID = c.CATEGORY_ID
    INNER JOIN dbo.MEASUREMENT_UNITS u ON p.UNIT_ID = u.UNIT_ID
    LEFT JOIN dbo.PRODUCT_PRICES pr ON p.PRODUCT_ID = pr.PRODUCT_ID AND pr.IS_ACTIVE = 1
    LEFT JOIN dbo.PRODUCT_IMAGES img ON p.PRODUCT_ID = img.PRODUCT_ID
    WHERE p.IS_ACTIVE = 1
      AND p.IS_DELETED = 0
      AND p.IS_FEATURED = 1
    ORDER BY p.CREATED_AT DESC;
END;
GO
