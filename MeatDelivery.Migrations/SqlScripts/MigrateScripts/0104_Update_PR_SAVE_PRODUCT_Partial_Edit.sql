-- Migration Script: 0104_Update_PR_SAVE_PRODUCT_Partial_Edit.sql
-- Description: Update PR_SAVE_PRODUCT to preserve existing values when nulls are passed in EDIT mode.

EXEC('
CREATE OR ALTER PROCEDURE dbo.PR_SAVE_PRODUCT
(
    @MODE                       VARCHAR(10),
    @PRODUCT_ID                 BIGINT          = NULL,
    @CATEGORY_ID                BIGINT          = NULL,
    @PRODUCT_NAME_EN            NVARCHAR(200)   = NULL,
    @PRODUCT_NAME_AR            NVARCHAR(200)   = NULL,
    @DESCRIPTION_EN             NVARCHAR(MAX)   = NULL,
    @DESCRIPTION_AR             NVARCHAR(MAX)   = NULL,
    @IS_CUSTOMIZABLE            BIT             = NULL,
    @CUSTOMIZATION_TEMPLATE_ID  BIGINT          = NULL,
    @UNIT_ID                    BIGINT          = NULL,
    @PRICE                      DECIMAL(18,2)   = NULL,
    @DISCOUNT_PERCENTAGE        DECIMAL(5,2)    = NULL,
    @STOCK_COUNT                DECIMAL(18,3)   = NULL,
    @PRIMARY_URL                NVARCHAR(500)   = NULL,
    @SECONDARY_URL              NVARCHAR(500)   = NULL,
    @TERTIARY_URL               NVARCHAR(500)   = NULL,
    @IS_FEATURED                BIT             = NULL,
    @IS_PREORDERABLE            BIT             = NULL,
    @IS_ACTIVE                  BIT             = NULL,
    @IS_NEW_ARRIVAL             BIT             = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @MODE = UPPER(LTRIM(RTRIM(@MODE)));

    IF @MODE = ''ADD''
    BEGIN
        IF @CATEGORY_ID IS NULL OR @CATEGORY_ID <= 0
        BEGIN
            THROW 50001, ''Valid CategoryId is required.'', 1;
        END

        IF NOT EXISTS (SELECT 1 FROM dbo.CATEGORIES WHERE CATEGORY_ID = @CATEGORY_ID)
        BEGIN
            THROW 50002, ''Category not found.'', 1;
        END

        IF @PRODUCT_NAME_EN IS NULL OR LTRIM(RTRIM(@PRODUCT_NAME_EN)) = ''''
        BEGIN
            THROW 50003, ''English Product Name is required.'', 1;
        END

        IF @PRODUCT_NAME_AR IS NULL OR LTRIM(RTRIM(@PRODUCT_NAME_AR)) = ''''
        BEGIN
            THROW 50004, ''Arabic Product Name is required.'', 1;
        END

        IF @UNIT_ID IS NULL OR @UNIT_ID <= 0
        BEGIN
            THROW 50005, ''Valid UnitId is required.'', 1;
        END

        IF NOT EXISTS (SELECT 1 FROM dbo.MEASUREMENT_UNITS WHERE UNIT_ID = @UNIT_ID AND IS_ACTIVE = 1)
        BEGIN
            THROW 50006, ''Measurement unit not found or inactive.'', 1;
        END

        IF @PRICE IS NULL OR @PRICE <= 0
        BEGIN
            THROW 50007, ''Price must be greater than 0.'', 1;
        END

        IF @PRIMARY_URL IS NULL OR LTRIM(RTRIM(@PRIMARY_URL)) = ''''
        BEGIN
            THROW 50008, ''Primary image URL is required.'', 1;
        END

        IF @CUSTOMIZATION_TEMPLATE_ID IS NOT NULL AND @CUSTOMIZATION_TEMPLATE_ID > 0
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_TEMPLATES WHERE CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID AND IS_ACTIVE = 1)
            BEGIN
                THROW 50009, ''Customization Template not found or inactive.'', 1;
            END
        END

        BEGIN TRANSACTION;

        BEGIN TRY
            DECLARE @DOC_NO VARCHAR(50);
            EXEC dbo.PR_GET_NEXT_DOC_NO @DOCTYPE = ''PROD'', @DOC_NO = @DOC_NO OUTPUT;

            INSERT INTO dbo.PRODUCTS
            (
                CATEGORY_ID, DOC_NO, DOC_TYPE, PRODUCT_NAME_EN, PRODUCT_NAME_AR,
                DESCRIPTION_EN, DESCRIPTION_AR, IS_CUSTOMIZABLE, CUSTOMIZATION_TEMPLATE_ID,
                UNIT_ID, DISCOUNT_PERCENTAGE, STOCK_COUNT, IS_FEATURED, IS_PREORDERABLE,
                IS_ACTIVE, IS_DELETED, DELETED_AT, IS_NEW_ARRIVAL, CREATED_AT, UPDATED_AT
            )
            VALUES
            (
                @CATEGORY_ID, @DOC_NO, ''PROD'', LTRIM(RTRIM(@PRODUCT_NAME_EN)), LTRIM(RTRIM(@PRODUCT_NAME_AR)),
                @DESCRIPTION_EN, @DESCRIPTION_AR, ISNULL(@IS_CUSTOMIZABLE, 0), @CUSTOMIZATION_TEMPLATE_ID,
                @UNIT_ID, ISNULL(@DISCOUNT_PERCENTAGE, 0.00), ISNULL(@STOCK_COUNT, 0), ISNULL(@IS_FEATURED, 0), ISNULL(@IS_PREORDERABLE, 0),
                ISNULL(@IS_ACTIVE, 1), 0, NULL, ISNULL(@IS_NEW_ARRIVAL, 0), SYSUTCDATETIME(), NULL
            );

            SET @PRODUCT_ID = SCOPE_IDENTITY();

            INSERT INTO dbo.PRODUCT_PRICES (PRODUCT_ID, PRICE, IS_ACTIVE, CREATED_AT)
            VALUES (@PRODUCT_ID, @PRICE, 1, SYSUTCDATETIME());

            INSERT INTO dbo.PRODUCT_IMAGES (PRODUCT_ID, PRIMARY_URL, SECONDARY_URL, TERTIARY_URL)
            VALUES (@PRODUCT_ID, LTRIM(RTRIM(@PRIMARY_URL)), @SECONDARY_URL, @TERTIARY_URL);

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
                p.IS_NEW_ARRIVAL AS IsNewArrival,
                p.CREATED_AT AS CreatedAt,
                p.UPDATED_AT AS UpdatedAt
            FROM dbo.PRODUCTS p
            INNER JOIN dbo.CATEGORIES c ON p.CATEGORY_ID = c.CATEGORY_ID
            INNER JOIN dbo.MEASUREMENT_UNITS u ON p.UNIT_ID = u.UNIT_ID
            LEFT JOIN dbo.PRODUCT_PRICES pr ON p.PRODUCT_ID = pr.PRODUCT_ID AND pr.IS_ACTIVE = 1
            LEFT JOIN dbo.PRODUCT_IMAGES img ON p.PRODUCT_ID = img.PRODUCT_ID
            WHERE p.PRODUCT_ID = @PRODUCT_ID;

            RETURN;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;

    IF @MODE = ''EDIT''
    BEGIN
        IF @PRODUCT_ID IS NULL OR @PRODUCT_ID <= 0
        BEGIN
            THROW 50020, ''Valid ProductId is required for EDIT mode.'', 1;
        END

        IF NOT EXISTS (SELECT 1 FROM dbo.PRODUCTS WHERE PRODUCT_ID = @PRODUCT_ID AND (IS_DELETED = 0 OR IS_DELETED IS NULL))
        BEGIN
            THROW 50021, ''Product not found.'', 1;
        END

        BEGIN TRANSACTION;

        BEGIN TRY
            UPDATE dbo.PRODUCTS
            SET CATEGORY_ID = ISNULL(@CATEGORY_ID, CATEGORY_ID),
                PRODUCT_NAME_EN = ISNULL(@PRODUCT_NAME_EN, PRODUCT_NAME_EN),
                PRODUCT_NAME_AR = ISNULL(@PRODUCT_NAME_AR, PRODUCT_NAME_AR),
                DESCRIPTION_EN = ISNULL(@DESCRIPTION_EN, DESCRIPTION_EN),
                DESCRIPTION_AR = ISNULL(@DESCRIPTION_AR, DESCRIPTION_AR),
                IS_CUSTOMIZABLE = ISNULL(@IS_CUSTOMIZABLE, IS_CUSTOMIZABLE),
                CUSTOMIZATION_TEMPLATE_ID = ISNULL(@CUSTOMIZATION_TEMPLATE_ID, CUSTOMIZATION_TEMPLATE_ID),
                UNIT_ID = ISNULL(@UNIT_ID, UNIT_ID),
                DISCOUNT_PERCENTAGE = ISNULL(@DISCOUNT_PERCENTAGE, DISCOUNT_PERCENTAGE),
                STOCK_COUNT = ISNULL(@STOCK_COUNT, STOCK_COUNT),
                IS_ACTIVE = ISNULL(@IS_ACTIVE, IS_ACTIVE),
                IS_FEATURED = ISNULL(@IS_FEATURED, IS_FEATURED),
                IS_PREORDERABLE = ISNULL(@IS_PREORDERABLE, IS_PREORDERABLE),
                IS_NEW_ARRIVAL = ISNULL(@IS_NEW_ARRIVAL, IS_NEW_ARRIVAL),
                UPDATED_AT = SYSUTCDATETIME()
            WHERE PRODUCT_ID = @PRODUCT_ID;

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
                        SECONDARY_URL = ISNULL(@SECONDARY_URL, SECONDARY_URL),
                        TERTIARY_URL = ISNULL(@TERTIARY_URL, TERTIARY_URL)
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
                p.IS_NEW_ARRIVAL AS IsNewArrival,
                p.CREATED_AT AS CreatedAt,
                p.UPDATED_AT AS UpdatedAt
            FROM dbo.PRODUCTS p
            INNER JOIN dbo.CATEGORIES c ON p.CATEGORY_ID = c.CATEGORY_ID
            INNER JOIN dbo.MEASUREMENT_UNITS u ON p.UNIT_ID = u.UNIT_ID
            LEFT JOIN dbo.PRODUCT_PRICES pr ON p.PRODUCT_ID = pr.PRODUCT_ID AND pr.IS_ACTIVE = 1
            LEFT JOIN dbo.PRODUCT_IMAGES img ON p.PRODUCT_ID = img.PRODUCT_ID
            WHERE p.PRODUCT_ID = @PRODUCT_ID;

            RETURN;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            THROW;
        END CATCH;
    END;

    IF @MODE = ''DELETE''
    BEGIN
        UPDATE dbo.PRODUCTS
        SET IS_ACTIVE = 0, IS_DELETED = 1, DELETED_AT = SYSUTCDATETIME(), UPDATED_AT = SYSUTCDATETIME()
        WHERE PRODUCT_ID = @PRODUCT_ID;

        SELECT NULL AS ProductId WHERE 1 = 0;
        RETURN;
    END;

    THROW 50030, ''Invalid Mode specified. Use ADD, EDIT, or DELETE.'', 1;
END;');
GO
