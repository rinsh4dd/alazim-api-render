-- Migration: 0049_Add_IsPreorderable_To_Products.sql
-- Description: Adds IS_PREORDERABLE column to dbo.PRODUCTS and updates PR_SAVE_PRODUCT and PR_GET_PRODUCTS stored procedures.

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.PRODUCTS') AND name = 'IS_PREORDERABLE')
BEGIN
    ALTER TABLE dbo.PRODUCTS ADD IS_PREORDERABLE BIT NOT NULL DEFAULT 0;
END;
GO

IF OBJECT_ID('dbo.PR_SAVE_PRODUCT', 'P') IS NOT NULL
    DROP PROCEDURE dbo.PR_SAVE_PRODUCT;
GO

EXEC('
CREATE PROCEDURE dbo.PR_SAVE_PRODUCT
(
    @MODE                       VARCHAR(10),

    @PRODUCT_ID                 BIGINT         = NULL,
    @CATEGORY_ID                BIGINT         = NULL,
    @PRODUCT_NAME_EN            NVARCHAR(200)  = NULL,
    @PRODUCT_NAME_AR            NVARCHAR(200)  = NULL,
    @DESCRIPTION_EN             NVARCHAR(2000) = NULL,
    @DESCRIPTION_AR             NVARCHAR(2000) = NULL,
    @IS_CUSTOMIZABLE            BIT            = 0,
    @CUSTOMIZATION_TEMPLATE_ID  BIGINT         = NULL,
    @UNIT_ID                    INT            = NULL,
    @DISCOUNT_PERCENTAGE        DECIMAL(5,2)   = 0,
    @INITIAL_STOCK_COUNT        DECIMAL(18,3)  = 0,
    @PRICE                      DECIMAL(18,2)  = NULL,
    @PRIMARY_URL                VARCHAR(500)   = NULL,
    @SECONDARY_URL              VARCHAR(500)   = NULL,
    @TERTIARY_URL               VARCHAR(500)   = NULL,
    @IS_FEATURED                BIT            = 0,
    @IS_PREORDERABLE            BIT            = 0,
    @IS_ACTIVE                  BIT            = 1
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @MODE = UPPER(LTRIM(RTRIM(@MODE)));

    BEGIN TRY
        IF @MODE = ''ADD''
        BEGIN
            BEGIN TRANSACTION;

            DECLARE @AllocatedDocNo VARCHAR(50) = NULL;

            EXEC dbo.PR_GET_NEXT_DOC_NO
                @DOCTYPE = ''PROD'',
                @DOC_NO = @AllocatedDocNo OUTPUT;

            INSERT INTO dbo.PRODUCTS
            (
                CATEGORY_ID,
                DOC_NO,
                DOC_TYPE,
                PRODUCT_NAME_EN,
                PRODUCT_NAME_AR,
                DESCRIPTION_EN,
                DESCRIPTION_AR,
                IS_CUSTOMIZABLE,
                CUSTOMIZATION_TEMPLATE_ID,
                UNIT_ID,
                DISCOUNT_PERCENTAGE,
                STOCK_COUNT,
                IS_ACTIVE,
                IS_DELETED,
                IS_FEATURED,
                IS_PREORDERABLE,
                CREATED_AT
            )
            VALUES
            (
                @CATEGORY_ID,
                @AllocatedDocNo,
                ''PROD'',
                @PRODUCT_NAME_EN,
                @PRODUCT_NAME_AR,
                @DESCRIPTION_EN,
                @DESCRIPTION_AR,
                ISNULL(@IS_CUSTOMIZABLE, 0),
                @CUSTOMIZATION_TEMPLATE_ID,
                @UNIT_ID,
                ISNULL(@DISCOUNT_PERCENTAGE, 0),
                ISNULL(@INITIAL_STOCK_COUNT, 0),
                ISNULL(@IS_ACTIVE, 1),
                0,
                ISNULL(@IS_FEATURED, 0),
                ISNULL(@IS_PREORDERABLE, 0),
                SYSUTCDATETIME()
            );

            SET @PRODUCT_ID = SCOPE_IDENTITY();

            IF @PRICE IS NOT NULL
            BEGIN
                INSERT INTO dbo.PRODUCT_PRICES (PRODUCT_ID, PRICE, IS_ACTIVE, CREATED_AT)
                VALUES (@PRODUCT_ID, @PRICE, 1, SYSUTCDATETIME());
            END

            IF @PRIMARY_URL IS NOT NULL
            BEGIN
                INSERT INTO dbo.PRODUCT_IMAGES (PRODUCT_ID, PRIMARY_URL, SECONDARY_URL, TERTIARY_URL)
                VALUES (@PRODUCT_ID, @PRIMARY_URL, @SECONDARY_URL, @TERTIARY_URL);
            END

            COMMIT TRANSACTION;

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
                CASE WHEN p.CREATED_AT >= DATEADD(DAY, -10, SYSUTCDATETIME()) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsNewArrival,
                p.CREATED_AT AS CreatedAt,
                p.UPDATED_AT AS UpdatedAt
            FROM dbo.PRODUCTS p
            INNER JOIN dbo.CATEGORIES c ON p.CATEGORY_ID = c.CATEGORY_ID
            INNER JOIN dbo.MEASUREMENT_UNITS u ON p.UNIT_ID = u.UNIT_ID
            LEFT JOIN dbo.PRODUCT_PRICES pr ON p.PRODUCT_ID = pr.PRODUCT_ID AND pr.IS_ACTIVE = 1
            LEFT JOIN dbo.PRODUCT_IMAGES img ON p.PRODUCT_ID = img.PRODUCT_ID
            WHERE p.PRODUCT_ID = @PRODUCT_ID;

            RETURN;
        END;

        IF @MODE = ''EDIT''
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.PRODUCTS WHERE PRODUCT_ID = @PRODUCT_ID AND IS_DELETED = 0)
            BEGIN
                THROW 50031, ''Product not found.'', 1;
            END

            BEGIN TRANSACTION;

            UPDATE dbo.PRODUCTS
            SET CATEGORY_ID = ISNULL(@CATEGORY_ID, CATEGORY_ID),
                PRODUCT_NAME_EN = ISNULL(@PRODUCT_NAME_EN, PRODUCT_NAME_EN),
                PRODUCT_NAME_AR = ISNULL(@PRODUCT_NAME_AR, PRODUCT_NAME_AR),
                DESCRIPTION_EN = @DESCRIPTION_EN,
                DESCRIPTION_AR = @DESCRIPTION_AR,
                IS_CUSTOMIZABLE = ISNULL(@IS_CUSTOMIZABLE, IS_CUSTOMIZABLE),
                CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID,
                UNIT_ID = ISNULL(@UNIT_ID, UNIT_ID),
                DISCOUNT_PERCENTAGE = ISNULL(@DISCOUNT_PERCENTAGE, DISCOUNT_PERCENTAGE),
                IS_ACTIVE = ISNULL(@IS_ACTIVE, IS_ACTIVE),
                IS_FEATURED = ISNULL(@IS_FEATURED, IS_FEATURED),
                IS_PREORDERABLE = ISNULL(@IS_PREORDERABLE, IS_PREORDERABLE),
                UPDATED_AT = SYSUTCDATETIME()
            WHERE PRODUCT_ID = @PRODUCT_ID AND IS_DELETED = 0;

            IF @PRICE IS NOT NULL
            BEGIN
                DECLARE @CurrentPrice DECIMAL(18,2);
                SELECT TOP 1 @CurrentPrice = PRICE FROM dbo.PRODUCT_PRICES WHERE PRODUCT_ID = @PRODUCT_ID AND IS_ACTIVE = 1;

                IF @CurrentPrice IS NULL OR @CurrentPrice <> @PRICE
                BEGIN
                    UPDATE dbo.PRODUCT_PRICES
                    SET IS_ACTIVE = 0, UPDATED_AT = SYSUTCDATETIME()
                    WHERE PRODUCT_ID = @PRODUCT_ID AND IS_ACTIVE = 1;

                    INSERT INTO dbo.PRODUCT_PRICES (PRODUCT_ID, PRICE, IS_ACTIVE, CREATED_AT)
                    VALUES (@PRODUCT_ID, @PRICE, 1, SYSUTCDATETIME());
                END
            END

            IF @PRIMARY_URL IS NOT NULL
            BEGIN
                IF EXISTS (SELECT 1 FROM dbo.PRODUCT_IMAGES WHERE PRODUCT_ID = @PRODUCT_ID)
                BEGIN
                    UPDATE dbo.PRODUCT_IMAGES
                    SET PRIMARY_URL = @PRIMARY_URL,
                        SECONDARY_URL = @SECONDARY_URL,
                        TERTIARY_URL = @TERTIARY_URL
                    WHERE PRODUCT_ID = @PRODUCT_ID;
                END
                ELSE
                BEGIN
                    INSERT INTO dbo.PRODUCT_IMAGES (PRODUCT_ID, PRIMARY_URL, SECONDARY_URL, TERTIARY_URL)
                    VALUES (@PRODUCT_ID, @PRIMARY_URL, @SECONDARY_URL, @TERTIARY_URL);
                END
            END

            COMMIT TRANSACTION;

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
                CASE WHEN p.CREATED_AT >= DATEADD(DAY, -10, SYSUTCDATETIME()) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsNewArrival,
                p.CREATED_AT AS CreatedAt,
                p.UPDATED_AT AS UpdatedAt
            FROM dbo.PRODUCTS p
            INNER JOIN dbo.CATEGORIES c ON p.CATEGORY_ID = c.CATEGORY_ID
            INNER JOIN dbo.MEASUREMENT_UNITS u ON p.UNIT_ID = u.UNIT_ID
            LEFT JOIN dbo.PRODUCT_PRICES pr ON p.PRODUCT_ID = pr.PRODUCT_ID AND pr.IS_ACTIVE = 1
            LEFT JOIN dbo.PRODUCT_IMAGES img ON p.PRODUCT_ID = img.PRODUCT_ID
            WHERE p.PRODUCT_ID = @PRODUCT_ID;

            RETURN;
        END;

        IF @MODE = ''DELETE''
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.PRODUCTS WHERE PRODUCT_ID = @PRODUCT_ID AND IS_DELETED = 0)
            BEGIN
                THROW 50031, ''Product not found.'', 1;
            END

            BEGIN TRANSACTION;

            UPDATE dbo.PRODUCTS
            SET IS_ACTIVE = 0,
                IS_DELETED = 1,
                DELETED_AT = SYSUTCDATETIME(),
                UPDATED_AT = SYSUTCDATETIME()
            WHERE PRODUCT_ID = @PRODUCT_ID;

            COMMIT TRANSACTION;

            SELECT
                p.PRODUCT_ID AS ProductId,
                p.DOC_TYPE AS DocType,
                p.DOC_NO AS DocNo,
                ''DELETE'' AS Mode
            FROM dbo.PRODUCTS p
            WHERE p.PRODUCT_ID = @PRODUCT_ID;

            RETURN;
        END;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
');
GO

IF OBJECT_ID('dbo.PR_GET_PRODUCTS', 'P') IS NOT NULL
    DROP PROCEDURE dbo.PR_GET_PRODUCTS;
GO

EXEC('
CREATE PROCEDURE dbo.PR_GET_PRODUCTS
    @PRODUCT_ID     BIGINT = NULL,
    @CATEGORY_ID    BIGINT = NULL,
    @SEARCH_TERM    NVARCHAR(200) = NULL,
    @IS_FEATURED    BIT = NULL,
    @IS_NEW_ARRIVAL BIT = NULL,
    @IS_PREORDERABLE BIT = NULL,
    @IS_ACTIVE      BIT = NULL,
    @IS_DELETED     BIT = NULL,
    @PAGE_NUMBER    INT = 1,
    @PAGE_SIZE      INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    SET @PAGE_NUMBER = ISNULL(@PAGE_NUMBER, 1);
    IF @PAGE_NUMBER < 1 SET @PAGE_NUMBER = 1;

    SET @PAGE_SIZE = ISNULL(@PAGE_SIZE, 10);
    IF @PAGE_SIZE < 1 SET @PAGE_SIZE = 10;

    SET @SEARCH_TERM = NULLIF(LTRIM(RTRIM(@SEARCH_TERM)), '''');

    -- 1. Total Count
    SELECT COUNT(1)
    FROM dbo.PRODUCTS p
    WHERE (@PRODUCT_ID IS NULL OR p.PRODUCT_ID = @PRODUCT_ID)
      AND (@CATEGORY_ID IS NULL OR p.CATEGORY_ID = @CATEGORY_ID)
      AND (@IS_FEATURED IS NULL OR p.IS_FEATURED = @IS_FEATURED)
      AND (@IS_PREORDERABLE IS NULL OR p.IS_PREORDERABLE = @IS_PREORDERABLE)
      AND (@IS_ACTIVE IS NULL OR p.IS_ACTIVE = @IS_ACTIVE)
      AND (@IS_DELETED IS NULL OR p.IS_DELETED = @IS_DELETED)
      AND (@IS_NEW_ARRIVAL IS NULL OR (@IS_NEW_ARRIVAL = 1 AND p.CREATED_AT >= DATEADD(DAY, -10, SYSUTCDATETIME())) OR (@IS_NEW_ARRIVAL = 0 AND p.CREATED_AT < DATEADD(DAY, -10, SYSUTCDATETIME())))
      AND (@SEARCH_TERM IS NULL OR p.PRODUCT_NAME_EN LIKE ''%'' + @SEARCH_TERM + ''%'' OR p.PRODUCT_NAME_AR LIKE ''%'' + @SEARCH_TERM + ''%'' OR p.DOC_NO LIKE ''%'' + @SEARCH_TERM + ''%'');

    -- 2. Items Result Set
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
        CASE WHEN p.CREATED_AT >= DATEADD(DAY, -10, SYSUTCDATETIME()) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsNewArrival,
        p.CREATED_AT AS CreatedAt,
        p.UPDATED_AT AS UpdatedAt
    FROM dbo.PRODUCTS p
    INNER JOIN dbo.CATEGORIES c ON p.CATEGORY_ID = c.CATEGORY_ID
    INNER JOIN dbo.MEASUREMENT_UNITS u ON p.UNIT_ID = u.UNIT_ID
    LEFT JOIN dbo.PRODUCT_PRICES pr ON p.PRODUCT_ID = pr.PRODUCT_ID AND pr.IS_ACTIVE = 1
    LEFT JOIN dbo.PRODUCT_IMAGES img ON p.PRODUCT_ID = img.PRODUCT_ID
    WHERE (@PRODUCT_ID IS NULL OR p.PRODUCT_ID = @PRODUCT_ID)
      AND (@CATEGORY_ID IS NULL OR p.CATEGORY_ID = @CATEGORY_ID)
      AND (@IS_FEATURED IS NULL OR p.IS_FEATURED = @IS_FEATURED)
      AND (@IS_PREORDERABLE IS NULL OR p.IS_PREORDERABLE = @IS_PREORDERABLE)
      AND (@IS_ACTIVE IS NULL OR p.IS_ACTIVE = @IS_ACTIVE)
      AND (@IS_DELETED IS NULL OR p.IS_DELETED = @IS_DELETED)
      AND (@IS_NEW_ARRIVAL IS NULL OR (@IS_NEW_ARRIVAL = 1 AND p.CREATED_AT >= DATEADD(DAY, -10, SYSUTCDATETIME())) OR (@IS_NEW_ARRIVAL = 0 AND p.CREATED_AT < DATEADD(DAY, -10, SYSUTCDATETIME())))
      AND (@SEARCH_TERM IS NULL OR p.PRODUCT_NAME_EN LIKE ''%'' + @SEARCH_TERM + ''%'' OR p.PRODUCT_NAME_AR LIKE ''%'' + @SEARCH_TERM + ''%'' OR p.DOC_NO LIKE ''%'' + @SEARCH_TERM + ''%'')
    ORDER BY p.CREATED_AT DESC
    OFFSET (@PAGE_NUMBER - 1) * @PAGE_SIZE ROWS
    FETCH NEXT @PAGE_SIZE ROWS ONLY;
END;
');
GO
