-- =============================================================================
-- STORED PROCEDURE: dbo.PR_GET_PRODUCT_BY_ID
-- Description: Retrieves full product details including weight options,
--              prices, and gallery images across 3 result sets.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_GET_PRODUCT_BY_ID
    @PRODUCT_ID BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    -- Result Set 1: Master Product
    SELECT
        p.PRODUCT_ID AS ProductId,
        p.CATEGORY_ID AS CategoryId,
        c.CATEGORY_NAME_EN AS CategoryNameEn,
        p.DOC_NO AS DocNo,
        p.DOC_TYPE AS DocType,
        p.PRODUCT_NAME_EN AS ProductNameEn,
        p.PRODUCT_NAME_AR AS ProductNameAr,
        p.DESCRIPTION_EN AS DescriptionEn,
        p.DESCRIPTION_AR AS DescriptionAr,
        p.COUNTRY_OF_ORIGIN AS CountryOfOrigin,
        p.IS_HALAL_CERTIFIED AS IsHalalCertified,
        p.HALAL_CERTIFICATE_NO AS HalalCertificateNo,
        p.HALAL_CERTIFICATE_URL AS HalalCertificateUrl,
        p.NUTRITION_INFORMATION_EN AS NutritionInformationEn,
        p.NUTRITION_INFORMATION_AR AS NutritionInformationAr,
        p.STORAGE_INSTRUCTIONS_EN AS StorageInstructionsEn,
        p.STORAGE_INSTRUCTIONS_AR AS StorageInstructionsAr,
        p.IS_CUSTOMIZABLE AS IsCustomizable,
        p.CUSTOMIZATION_TEMPLATE_ID AS CustomizationTemplateId,
        p.DISPLAY_ORDER AS DisplayOrder,
        p.IS_FEATURED AS IsFeatured,
        p.IS_BESTSELLER AS IsBestseller,
        p.IS_ACTIVE AS IsActive,
        p.CREATED_AT AS CreatedAt,
        p.UPDATED_AT AS UpdatedAt
    FROM dbo.PRODUCTS p
    LEFT JOIN dbo.CATEGORIES c ON p.CATEGORY_ID = c.CATEGORY_ID
    WHERE p.PRODUCT_ID = @PRODUCT_ID;

    -- Result Set 2: Weight Options & Prices
    SELECT
        w.PRODUCT_WEIGHT_OPTION_ID AS ProductWeightOptionId,
        w.PRODUCT_ID AS ProductId,
        w.UNIT_ID AS UnitId,
        u.UNIT AS Unit,
        u.UNIT_DESCRIPTION AS UnitDescription,
        w.UNIT_VALUE AS UnitValue,
        w.IS_CUSTOM_WEIGHT AS IsCustomWeight,
        w.MIN_WEIGHT AS MinWeight,
        w.MAX_WEIGHT AS MaxWeight,
        w.MIN_ORDER_QUANTITY AS MinOrderQuantity,
        w.MAX_ORDER_QUANTITY AS MaxOrderQuantity,
        w.QUANTITY_INCREMENT AS QuantityIncrement,
        w.IS_DEFAULT AS IsDefault,
        w.DISPLAY_ORDER AS DisplayOrder,
        w.IS_ACTIVE AS IsActive,
        pr.PRODUCT_PRICE_ID AS ProductPriceId,
        pr.PRICE_TYPE AS PriceType,
        pr.REGULAR_PRICE AS RegularPrice,
        pr.DISCOUNT_PRICE AS DiscountPrice,
        pr.CURRENCY_CODE AS CurrencyCode
    FROM dbo.PRODUCT_WEIGHT_OPTIONS w
    INNER JOIN dbo.MEASUREMENT_UNITS u ON w.UNIT_ID = u.UNIT_ID
    LEFT JOIN dbo.PRODUCT_PRICES pr ON w.PRODUCT_WEIGHT_OPTION_ID = pr.PRODUCT_WEIGHT_OPTION_ID
    WHERE w.PRODUCT_ID = @PRODUCT_ID
    ORDER BY w.DISPLAY_ORDER ASC, w.PRODUCT_WEIGHT_OPTION_ID ASC;

    -- Result Set 3: Product Gallery Images
    SELECT
        PRODUCT_IMAGE_ID AS ProductImageId,
        PRODUCT_ID AS ProductId,
        IMAGE_URL AS ImageUrl,
        IS_PRIMARY AS IsPrimary,
        DISPLAY_ORDER AS DisplayOrder,
        IS_ACTIVE AS IsActive
    FROM dbo.PRODUCT_IMAGES
    WHERE PRODUCT_ID = @PRODUCT_ID
    ORDER BY IS_PRIMARY DESC, DISPLAY_ORDER ASC;
END;
GO
