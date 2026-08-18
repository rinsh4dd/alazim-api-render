-- =============================================================================
-- Migration: 0041_Create_PR_GET_PRODUCTS.sql
-- Description: Creates unified stored procedure PR_GET_PRODUCTS.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_GET_PRODUCTS
    @USER_TYPE                  VARCHAR(20) = 'GUEST',
    @USER_ID                    BIGINT = NULL,
    @PRODUCT_ID                 BIGINT = NULL,
    @CATEGORY_ID                BIGINT = NULL,
    @SEARCH_TERM                NVARCHAR(150) = NULL,
    @IS_FEATURED                BIT = NULL,
    @IS_BESTSELLER              BIT = NULL,
    @IS_ACTIVE                  BIT = NULL,
    @IS_DELETED                 BIT = NULL,
    @IS_WISHLISTED_ONLY         BIT = NULL,
    @IS_RECENTLY_ORDERED_ONLY   BIT = NULL,
    @MIN_PRICE                  DECIMAL(18,2) = NULL,
    @MAX_PRICE                  DECIMAL(18,2) = NULL,
    @SORT_BY                    VARCHAR(50) = 'DisplayOrder',
    @SORT_ORDER                 VARCHAR(10) = 'ASC',
    @PAGE_NUMBER                INT = 1,
    @PAGE_SIZE                  INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    IF @USER_TYPE IS NULL OR UPPER(@USER_TYPE) NOT IN ('GUEST', 'USER', 'ADMIN')
        SET @USER_TYPE = 'GUEST';

    IF @PAGE_NUMBER IS NULL OR @PAGE_NUMBER < 1 SET @PAGE_NUMBER = 1;
    IF @PAGE_SIZE IS NULL OR @PAGE_SIZE < 1 SET @PAGE_SIZE = 10;
    IF @PAGE_SIZE > 100 SET @PAGE_SIZE = 100;

    SET @SEARCH_TERM = LTRIM(RTRIM(@SEARCH_TERM));
    IF @SEARCH_TERM = '' SET @SEARCH_TERM = NULL;

    IF UPPER(@USER_TYPE) IN ('GUEST', 'USER')
    BEGIN
        SET @IS_ACTIVE = 1;
        SET @IS_DELETED = 0;
    END
    ELSE IF UPPER(@USER_TYPE) = 'ADMIN'
    BEGIN
        IF @IS_DELETED IS NULL SET @IS_DELETED = 0;
    END;

    CREATE TABLE #PagedProductIds
    (
        PRODUCT_ID BIGINT PRIMARY KEY,
        ROW_NUM INT IDENTITY(1,1)
    );

    WITH BaseProducts AS
    (
        SELECT p.PRODUCT_ID
        FROM dbo.PRODUCTS p
        WHERE (@PRODUCT_ID IS NULL OR p.PRODUCT_ID = @PRODUCT_ID)
          AND (@CATEGORY_ID IS NULL OR p.CATEGORY_ID = @CATEGORY_ID)
          AND (@IS_FEATURED IS NULL OR p.IS_FEATURED = @IS_FEATURED)
          AND (@IS_BESTSELLER IS NULL OR p.IS_BESTSELLER = @IS_BESTSELLER)
          AND (@IS_ACTIVE IS NULL OR p.IS_ACTIVE = @IS_ACTIVE)
          AND (@IS_DELETED IS NULL OR p.IS_DELETED = @IS_DELETED)
          AND (@SEARCH_TERM IS NULL OR
               p.PRODUCT_NAME_EN LIKE '%' + @SEARCH_TERM + '%' OR
               p.PRODUCT_NAME_AR LIKE '%' + @SEARCH_TERM + '%' OR
               p.DESCRIPTION_EN LIKE '%' + @SEARCH_TERM + '%' OR
               p.DESCRIPTION_AR LIKE '%' + @SEARCH_TERM + '%' OR
               p.DOC_NO LIKE '%' + @SEARCH_TERM + '%' OR
               p.COUNTRY_OF_ORIGIN LIKE '%' + @SEARCH_TERM + '%')
          AND (@MIN_PRICE IS NULL OR EXISTS (
              SELECT 1 FROM dbo.PRODUCT_PRICES pr 
              WHERE pr.PRODUCT_ID = p.PRODUCT_ID AND (pr.DISCOUNT_PRICE IS NOT NULL AND pr.DISCOUNT_PRICE >= @MIN_PRICE OR pr.REGULAR_PRICE >= @MIN_PRICE)
          ))
          AND (@MAX_PRICE IS NULL OR EXISTS (
              SELECT 1 FROM dbo.PRODUCT_PRICES pr 
              WHERE pr.PRODUCT_ID = p.PRODUCT_ID AND (pr.DISCOUNT_PRICE IS NOT NULL AND pr.DISCOUNT_PRICE <= @MAX_PRICE OR pr.REGULAR_PRICE <= @MAX_PRICE)
          ))
          AND (@IS_WISHLISTED_ONLY IS NULL OR @IS_WISHLISTED_ONLY = 0 OR (@USER_ID IS NOT NULL AND EXISTS (
              SELECT 1 FROM dbo.CUSTOMER_WISHLISTS w WHERE w.CUSTOMER_USER_ID = @USER_ID AND w.PRODUCT_ID = p.PRODUCT_ID
          )))
          AND (@IS_RECENTLY_ORDERED_ONLY IS NULL OR @IS_RECENTLY_ORDERED_ONLY = 0 OR (@USER_ID IS NOT NULL AND EXISTS (
              SELECT 1 FROM dbo.ORDER_ITEMS oi INNER JOIN dbo.ORDERS o ON oi.ORDER_ID = o.ORDER_ID WHERE o.CUSTOMER_USER_ID = @USER_ID AND oi.PRODUCT_ID = p.PRODUCT_ID
          )))
    )
    INSERT INTO #PagedProductIds (PRODUCT_ID)
    SELECT bp.PRODUCT_ID
    FROM BaseProducts bp
    INNER JOIN dbo.PRODUCTS p ON bp.PRODUCT_ID = p.PRODUCT_ID
    ORDER BY
        CASE WHEN @SORT_BY = 'DisplayOrder' AND UPPER(@SORT_ORDER) = 'ASC' THEN p.DISPLAY_ORDER END ASC,
        CASE WHEN @SORT_BY = 'DisplayOrder' AND UPPER(@SORT_ORDER) = 'DESC' THEN p.DISPLAY_ORDER END DESC,
        CASE WHEN @SORT_BY = 'ProductNameEn' AND UPPER(@SORT_ORDER) = 'ASC' THEN p.PRODUCT_NAME_EN END ASC,
        CASE WHEN @SORT_BY = 'ProductNameEn' AND UPPER(@SORT_ORDER) = 'DESC' THEN p.PRODUCT_NAME_EN END DESC,
        CASE WHEN @SORT_BY = 'CreatedAt' AND UPPER(@SORT_ORDER) = 'ASC' THEN p.CREATED_AT END ASC,
        CASE WHEN @SORT_BY = 'CreatedAt' AND UPPER(@SORT_ORDER) = 'DESC' THEN p.CREATED_AT END DESC,
        p.PRODUCT_ID DESC
    OFFSET (@PAGE_NUMBER - 1) * @PAGE_SIZE ROWS
    FETCH NEXT @PAGE_SIZE ROWS ONLY;

    -- Result Set 1: Total Records Count
    SELECT COUNT(1) AS TotalRecords
    FROM dbo.PRODUCTS p
    WHERE (@PRODUCT_ID IS NULL OR p.PRODUCT_ID = @PRODUCT_ID)
      AND (@CATEGORY_ID IS NULL OR p.CATEGORY_ID = @CATEGORY_ID)
      AND (@IS_FEATURED IS NULL OR p.IS_FEATURED = @IS_FEATURED)
      AND (@IS_BESTSELLER IS NULL OR p.IS_BESTSELLER = @IS_BESTSELLER)
      AND (@IS_ACTIVE IS NULL OR p.IS_ACTIVE = @IS_ACTIVE)
      AND (@IS_DELETED IS NULL OR p.IS_DELETED = @IS_DELETED)
      AND (@SEARCH_TERM IS NULL OR
           p.PRODUCT_NAME_EN LIKE '%' + @SEARCH_TERM + '%' OR
           p.PRODUCT_NAME_AR LIKE '%' + @SEARCH_TERM + '%' OR
           p.DESCRIPTION_EN LIKE '%' + @SEARCH_TERM + '%' OR
           p.DESCRIPTION_AR LIKE '%' + @SEARCH_TERM + '%' OR
           p.DOC_NO LIKE '%' + @SEARCH_TERM + '%' OR
           p.COUNTRY_OF_ORIGIN LIKE '%' + @SEARCH_TERM + '%')
      AND (@MIN_PRICE IS NULL OR EXISTS (
          SELECT 1 FROM dbo.PRODUCT_PRICES pr 
          WHERE pr.PRODUCT_ID = p.PRODUCT_ID AND (pr.DISCOUNT_PRICE IS NOT NULL AND pr.DISCOUNT_PRICE >= @MIN_PRICE OR pr.REGULAR_PRICE >= @MIN_PRICE)
      ))
      AND (@MAX_PRICE IS NULL OR EXISTS (
          SELECT 1 FROM dbo.PRODUCT_PRICES pr 
          WHERE pr.PRODUCT_ID = p.PRODUCT_ID AND (pr.DISCOUNT_PRICE IS NOT NULL AND pr.DISCOUNT_PRICE <= @MAX_PRICE OR pr.REGULAR_PRICE <= @MAX_PRICE)
      ))
      AND (@IS_WISHLISTED_ONLY IS NULL OR @IS_WISHLISTED_ONLY = 0 OR (@USER_ID IS NOT NULL AND EXISTS (
          SELECT 1 FROM dbo.CUSTOMER_WISHLISTS w WHERE w.CUSTOMER_USER_ID = @USER_ID AND w.PRODUCT_ID = p.PRODUCT_ID
      )))
      AND (@IS_RECENTLY_ORDERED_ONLY IS NULL OR @IS_RECENTLY_ORDERED_ONLY = 0 OR (@USER_ID IS NOT NULL AND EXISTS (
          SELECT 1 FROM dbo.ORDER_ITEMS oi INNER JOIN dbo.ORDERS o ON oi.ORDER_ID = o.ORDER_ID WHERE o.CUSTOMER_USER_ID = @USER_ID AND oi.PRODUCT_ID = p.PRODUCT_ID
      )));

    -- Result Set 2: Paged Products Master
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
        p.IS_DELETED AS IsDeleted,
        p.DELETED_AT AS DeletedAt,
        p.CREATED_AT AS CreatedAt,
        p.UPDATED_AT AS UpdatedAt,
        CAST(CASE WHEN @USER_ID IS NOT NULL AND EXISTS (
            SELECT 1 FROM dbo.CUSTOMER_WISHLISTS w WHERE w.CUSTOMER_USER_ID = @USER_ID AND w.PRODUCT_ID = p.PRODUCT_ID
        ) THEN 1 ELSE 0 END AS BIT) AS IsWishlisted,
        CAST(CASE WHEN @USER_ID IS NOT NULL AND EXISTS (
            SELECT 1 FROM dbo.ORDER_ITEMS oi INNER JOIN dbo.ORDERS o ON oi.ORDER_ID = o.ORDER_ID WHERE o.CUSTOMER_USER_ID = @USER_ID AND oi.PRODUCT_ID = p.PRODUCT_ID
        ) THEN 1 ELSE 0 END AS BIT) AS IsRecentlyOrdered
    FROM #PagedProductIds page
    INNER JOIN dbo.PRODUCTS p ON page.PRODUCT_ID = p.PRODUCT_ID
    LEFT JOIN dbo.CATEGORIES c ON p.CATEGORY_ID = c.CATEGORY_ID
    ORDER BY page.ROW_NUM ASC;

    -- Result Set 3: Weight Options & Prices for Paged Products
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
    FROM #PagedProductIds page
    INNER JOIN dbo.PRODUCT_WEIGHT_OPTIONS w ON page.PRODUCT_ID = w.PRODUCT_ID
    INNER JOIN dbo.MEASUREMENT_UNITS u ON w.UNIT_ID = u.UNIT_ID
    LEFT JOIN dbo.PRODUCT_PRICES pr ON w.PRODUCT_WEIGHT_OPTION_ID = pr.PRODUCT_WEIGHT_OPTION_ID
    ORDER BY page.ROW_NUM ASC, w.DISPLAY_ORDER ASC, w.PRODUCT_WEIGHT_OPTION_ID ASC;

    -- Result Set 4: Gallery Images for Paged Products
    SELECT
        img.PRODUCT_IMAGE_ID AS ProductImageId,
        img.PRODUCT_ID AS ProductId,
        img.IMAGE_URL AS ImageUrl,
        img.IS_PRIMARY AS IsPrimary,
        img.DISPLAY_ORDER AS DisplayOrder,
        img.IS_ACTIVE AS IsActive
    FROM #PagedProductIds page
    INNER JOIN dbo.PRODUCT_IMAGES img ON page.PRODUCT_ID = img.PRODUCT_ID
    ORDER BY page.ROW_NUM ASC, img.IS_PRIMARY DESC, img.DISPLAY_ORDER ASC;

    DROP TABLE #PagedProductIds;
END;
GO
