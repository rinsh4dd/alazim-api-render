-- Migration: 0057_Create_Wishlist_Procedures.sql
-- Description: Creates stored procedures PR_TOGGLE_CUSTOMER_WISHLIST and PR_GET_CUSTOMER_WISHLIST.

IF OBJECT_ID('dbo.PR_TOGGLE_CUSTOMER_WISHLIST', 'P') IS NOT NULL
    DROP PROCEDURE dbo.PR_TOGGLE_CUSTOMER_WISHLIST;
GO

EXEC('
CREATE PROCEDURE dbo.PR_TOGGLE_CUSTOMER_WISHLIST
(
    @CUSTOMER_USER_ID   BIGINT,
    @PRODUCT_ID         BIGINT,
    @IN_WISHLIST        BIT = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.CUSTOMER_USERS WHERE USER_ID = @CUSTOMER_USER_ID)
    BEGIN
        THROW 50034, ''Customer user not found.'', 1;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.PRODUCTS WHERE PRODUCT_ID = @PRODUCT_ID AND IS_DELETED = 0)
    BEGIN
        THROW 50035, ''Product not found or deleted.'', 1;
    END

    BEGIN TRANSACTION;

    -- Ensure wishlist header exists for customer (1 wishlist per customer)
    DECLARE @WISHLIST_ID BIGINT;
    SELECT @WISHLIST_ID = WISHLIST_ID FROM dbo.WISHLISTS WHERE CUSTOMER_USER_ID = @CUSTOMER_USER_ID;

    IF @WISHLIST_ID IS NULL
    BEGIN
        INSERT INTO dbo.WISHLISTS (CUSTOMER_USER_ID, CREATED_AT)
        VALUES (@CUSTOMER_USER_ID, SYSUTCDATETIME());
        SET @WISHLIST_ID = SCOPE_IDENTITY();
    END

    SET @IN_WISHLIST = ISNULL(@IN_WISHLIST, 1);

    IF @IN_WISHLIST = 1
    BEGIN
        -- Add to wishlist if not already present
        IF NOT EXISTS (SELECT 1 FROM dbo.WISHLIST_ITEMS WHERE WISHLIST_ID = @WISHLIST_ID AND PRODUCT_ID = @PRODUCT_ID)
        BEGIN
            INSERT INTO dbo.WISHLIST_ITEMS (WISHLIST_ID, PRODUCT_ID, ADDED_AT)
            VALUES (@WISHLIST_ID, @PRODUCT_ID, SYSUTCDATETIME());
        END
    END
    ELSE
    BEGIN
        -- Remove from wishlist (clear when toggle)
        DELETE FROM dbo.WISHLIST_ITEMS
        WHERE WISHLIST_ID = @WISHLIST_ID AND PRODUCT_ID = @PRODUCT_ID;
    END

    UPDATE dbo.WISHLISTS
    SET UPDATED_AT = SYSUTCDATETIME()
    WHERE WISHLIST_ID = @WISHLIST_ID;

    COMMIT TRANSACTION;

    -- Grid 1: Wishlist toggle status
    SELECT
        @WISHLIST_ID AS WishlistId,
        @CUSTOMER_USER_ID AS CustomerUserId,
        @PRODUCT_ID AS ProductId,
        CAST(@IN_WISHLIST AS BIT) AS InWishlist,
        SYSUTCDATETIME() AS ActionTimestamp;

    -- Grid 2: Full Product Details
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
    WHERE p.PRODUCT_ID = @PRODUCT_ID;
END;
');
GO

IF OBJECT_ID('dbo.PR_GET_CUSTOMER_WISHLIST', 'P') IS NOT NULL
    DROP PROCEDURE dbo.PR_GET_CUSTOMER_WISHLIST;
GO

EXEC('
CREATE PROCEDURE dbo.PR_GET_CUSTOMER_WISHLIST
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

    -- Grid 1: Total records count
    SELECT COUNT(1) AS TotalRecords
    FROM dbo.WISHLIST_ITEMS wi
    INNER JOIN dbo.PRODUCTS p ON wi.PRODUCT_ID = p.PRODUCT_ID
    WHERE wi.WISHLIST_ID = @WISHLIST_ID AND p.IS_DELETED = 0 AND p.IS_ACTIVE = 1;

    -- Grid 2: Paginated wishlisted products
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
    FROM dbo.WISHLIST_ITEMS wi
    INNER JOIN dbo.PRODUCTS p ON wi.PRODUCT_ID = p.PRODUCT_ID
    INNER JOIN dbo.CATEGORIES c ON p.CATEGORY_ID = c.CATEGORY_ID
    INNER JOIN dbo.MEASUREMENT_UNITS u ON p.UNIT_ID = u.UNIT_ID
    LEFT JOIN dbo.PRODUCT_PRICES pr ON p.PRODUCT_ID = pr.PRODUCT_ID AND pr.IS_ACTIVE = 1
    LEFT JOIN dbo.PRODUCT_IMAGES img ON p.PRODUCT_ID = img.PRODUCT_ID
    WHERE wi.WISHLIST_ID = @WISHLIST_ID AND p.IS_DELETED = 0 AND p.IS_ACTIVE = 1
    ORDER BY wi.ADDED_AT DESC
    OFFSET @OFFSET ROWS
    FETCH NEXT @PAGE_SIZE ROWS ONLY;
END;
');
GO
