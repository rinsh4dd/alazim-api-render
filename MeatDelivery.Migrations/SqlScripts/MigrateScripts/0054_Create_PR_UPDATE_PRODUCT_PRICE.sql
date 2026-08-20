-- Migration: 0054_Create_PR_UPDATE_PRODUCT_PRICE.sql
-- Description: Creates stored procedure PR_UPDATE_PRODUCT_PRICE for price updates with history tracking.

IF OBJECT_ID('dbo.PR_UPDATE_PRODUCT_PRICE', 'P') IS NOT NULL
    DROP PROCEDURE dbo.PR_UPDATE_PRODUCT_PRICE;
GO

EXEC('
CREATE PROCEDURE dbo.PR_UPDATE_PRODUCT_PRICE
(
    @PRODUCT_ID           BIGINT,
    @PRICE                DECIMAL(18,2),
    @DISCOUNT_PERCENTAGE  DECIMAL(5,2) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.PRODUCTS WHERE PRODUCT_ID = @PRODUCT_ID AND IS_DELETED = 0)
    BEGIN
        THROW 50033, ''Product not found or has been deleted.'', 1;
    END

    BEGIN TRANSACTION;

    -- Option B: Deactivate existing active price record for audit trail
    UPDATE dbo.PRODUCT_PRICES
    SET IS_ACTIVE = 0,
        UPDATED_AT = SYSUTCDATETIME()
    WHERE PRODUCT_ID = @PRODUCT_ID AND IS_ACTIVE = 1;

    -- Insert new active price record
    INSERT INTO dbo.PRODUCT_PRICES
    (
        PRODUCT_ID,
        PRICE,
        IS_ACTIVE,
        CREATED_AT
    )
    VALUES
    (
        @PRODUCT_ID,
        @PRICE,
        1,
        SYSUTCDATETIME()
    );

    -- Update DISCOUNT_PERCENTAGE on PRODUCTS if provided
    IF @DISCOUNT_PERCENTAGE IS NOT NULL
    BEGIN
        UPDATE dbo.PRODUCTS
        SET DISCOUNT_PERCENTAGE = @DISCOUNT_PERCENTAGE,
            UPDATED_AT = SYSUTCDATETIME()
        WHERE PRODUCT_ID = @PRODUCT_ID;
    END
    ELSE
    BEGIN
        UPDATE dbo.PRODUCTS
        SET UPDATED_AT = SYSUTCDATETIME()
        WHERE PRODUCT_ID = @PRODUCT_ID;
    END

    COMMIT TRANSACTION;

    -- Return updated product details
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
    WHERE p.PRODUCT_ID = @PRODUCT_ID AND p.IS_DELETED = 0;
END;
');
GO
