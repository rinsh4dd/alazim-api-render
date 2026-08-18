-- =============================================================================
-- Migration: 0032_Fix_Product_Doc_Numbering.sql
-- Description: Seeds PRD1 DOCTYPE into dbo.M_DOC_NO and updates dbo.PR_SAVE_PRODUCT
--              to use dbo.PR_GET_NEXT_DOC_NO.
-- =============================================================================

-- 1. SEED PRD1 DOCTYPE IN M_DOC_NO IF NOT EXISTS
IF NOT EXISTS (SELECT 1 FROM dbo.M_DOC_NO WHERE DOCTYPE = 'PRD1')
BEGIN
    DECLARE @DefaultCompanyId BIGINT;
    SELECT TOP 1 @DefaultCompanyId = COMPANY_CONFIG_ID FROM dbo.COMPANY_CONFIG WHERE COMPANY_CODE = 'AL_AZIMA';

    INSERT INTO dbo.M_DOC_NO (MDOC, DOCTYPE, DESCRIPTION, COMPANY_CONFIG_ID, PREFIX, SUFFIX, DIGIT_NO, START_DOCNO, PERIODWISE_YN, PERIOD_TYPE, IS_ACTIVE)
    VALUES ('PRD', 'PRD1', 'Product Document Number', @DefaultCompanyId, 'PRD', NULL, 10, 0, 'N', 'NONE', 1);
END;
GO

-- 2. UPDATE STORED PROCEDURE PR_SAVE_PRODUCT
CREATE OR ALTER PROCEDURE dbo.PR_SAVE_PRODUCT
    @MODE                       VARCHAR(10),
    @PRODUCT_ID                 BIGINT = NULL,
    @CATEGORY_ID                BIGINT = NULL,
    @DOC_NO                     VARCHAR(50) = NULL,
    @DOC_TYPE                   VARCHAR(20) = 'PRD1',
    @PRODUCT_NAME_EN            NVARCHAR(200) = NULL,
    @PRODUCT_NAME_AR            NVARCHAR(200) = NULL,
    @DESCRIPTION_EN             NVARCHAR(2000) = NULL,
    @DESCRIPTION_AR             NVARCHAR(2000) = NULL,
    @COUNTRY_OF_ORIGIN          NVARCHAR(100) = NULL,
    @IS_HALAL_CERTIFIED         BIT = 1,
    @HALAL_CERTIFICATE_NO       VARCHAR(100) = NULL,
    @HALAL_CERTIFICATE_URL      VARCHAR(500) = NULL,
    @NUTRITION_INFORMATION_EN   NVARCHAR(2000) = NULL,
    @NUTRITION_INFORMATION_AR   NVARCHAR(2000) = NULL,
    @STORAGE_INSTRUCTIONS_EN    NVARCHAR(1000) = NULL,
    @STORAGE_INSTRUCTIONS_AR    NVARCHAR(1000) = NULL,
    @IS_CUSTOMIZABLE            BIT = 0,
    @CUSTOMIZATION_TEMPLATE_ID  BIGINT = NULL,
    @DISPLAY_ORDER              INT = 0,
    @IS_FEATURED                BIT = 0,
    @IS_BESTSELLER              BIT = 0,
    @IS_ACTIVE                  BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF ISNULL(@DOC_TYPE, '') = ''
        SET @DOC_TYPE = 'PRD1';

    -- =========================================================================
    -- MODE: ADD
    -- =========================================================================
    IF @MODE = 'ADD'
    BEGIN
        -- Auto-generate document number if not provided using PR_GET_NEXT_DOC_NO
        IF ISNULL(@DOC_NO, '') = ''
        BEGIN
            EXEC dbo.PR_GET_NEXT_DOC_NO 
                @DOCTYPE = @DOC_TYPE, 
                @DOC_NO = @DOC_NO OUTPUT;
        END;

        IF EXISTS (SELECT 1 FROM dbo.PRODUCTS WHERE DOC_NO = @DOC_NO)
        BEGIN
            RAISERROR('Product document number (DocNo) already exists.', 16, 1);
            RETURN;
        END;

        INSERT INTO dbo.PRODUCTS
        (
            CATEGORY_ID, DOC_NO, DOC_TYPE, PRODUCT_NAME_EN, PRODUCT_NAME_AR,
            DESCRIPTION_EN, DESCRIPTION_AR, COUNTRY_OF_ORIGIN,
            IS_HALAL_CERTIFIED, HALAL_CERTIFICATE_NO, HALAL_CERTIFICATE_URL,
            NUTRITION_INFORMATION_EN, NUTRITION_INFORMATION_AR,
            STORAGE_INSTRUCTIONS_EN, STORAGE_INSTRUCTIONS_AR,
            IS_CUSTOMIZABLE, CUSTOMIZATION_TEMPLATE_ID, DISPLAY_ORDER,
            IS_FEATURED, IS_BESTSELLER, IS_ACTIVE, CREATED_AT
        )
        VALUES
        (
            @CATEGORY_ID, @DOC_NO, @DOC_TYPE, @PRODUCT_NAME_EN, @PRODUCT_NAME_AR,
            @DESCRIPTION_EN, @DESCRIPTION_AR, @COUNTRY_OF_ORIGIN,
            ISNULL(@IS_HALAL_CERTIFIED, 1), @HALAL_CERTIFICATE_NO, @HALAL_CERTIFICATE_URL,
            @NUTRITION_INFORMATION_EN, @NUTRITION_INFORMATION_AR,
            @STORAGE_INSTRUCTIONS_EN, @STORAGE_INSTRUCTIONS_AR,
            ISNULL(@IS_CUSTOMIZABLE, 0), @CUSTOMIZATION_TEMPLATE_ID, ISNULL(@DISPLAY_ORDER, 0),
            ISNULL(@IS_FEATURED, 0), ISNULL(@IS_BESTSELLER, 0), ISNULL(@IS_ACTIVE, 1), SYSUTCDATETIME()
        );

        SET @PRODUCT_ID = CAST(SCOPE_IDENTITY() AS BIGINT);

        SELECT
            p.PRODUCT_ID AS ProductId, p.CATEGORY_ID AS CategoryId,
            c.CATEGORY_NAME_EN AS CategoryNameEn, p.DOC_NO AS DocNo, p.DOC_TYPE AS DocType,
            p.PRODUCT_NAME_EN AS ProductNameEn, p.PRODUCT_NAME_AR AS ProductNameAr,
            p.DESCRIPTION_EN AS DescriptionEn, p.DESCRIPTION_AR AS DescriptionAr,
            p.COUNTRY_OF_ORIGIN AS CountryOfOrigin,
            p.IS_HALAL_CERTIFIED AS IsHalalCertified, p.HALAL_CERTIFICATE_NO AS HalalCertificateNo,
            p.HALAL_CERTIFICATE_URL AS HalalCertificateUrl,
            p.NUTRITION_INFORMATION_EN AS NutritionInformationEn,
            p.NUTRITION_INFORMATION_AR AS NutritionInformationAr,
            p.STORAGE_INSTRUCTIONS_EN AS StorageInstructionsEn,
            p.STORAGE_INSTRUCTIONS_AR AS StorageInstructionsAr,
            p.IS_CUSTOMIZABLE AS IsCustomizable, p.CUSTOMIZATION_TEMPLATE_ID AS CustomizationTemplateId,
            p.DISPLAY_ORDER AS DisplayOrder, p.IS_FEATURED AS IsFeatured,
            p.IS_BESTSELLER AS IsBestseller, p.IS_ACTIVE AS IsActive,
            p.CREATED_AT AS CreatedAt, p.UPDATED_AT AS UpdatedAt
        FROM dbo.PRODUCTS p
        LEFT JOIN dbo.CATEGORIES c ON p.CATEGORY_ID = c.CATEGORY_ID
        WHERE p.PRODUCT_ID = @PRODUCT_ID;

        RETURN;
    END;

    -- =========================================================================
    -- MODE: EDIT
    -- =========================================================================
    IF @MODE = 'EDIT'
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.PRODUCTS WHERE DOC_NO = @DOC_NO AND PRODUCT_ID <> @PRODUCT_ID)
        BEGIN
            RAISERROR('Product document number (DocNo) already exists.', 16, 1);
            RETURN;
        END;

        UPDATE dbo.PRODUCTS
        SET
            CATEGORY_ID = ISNULL(@CATEGORY_ID, CATEGORY_ID),
            DOC_NO = ISNULL(@DOC_NO, DOC_NO),
            DOC_TYPE = ISNULL(@DOC_TYPE, DOC_TYPE),
            PRODUCT_NAME_EN = ISNULL(@PRODUCT_NAME_EN, PRODUCT_NAME_EN),
            PRODUCT_NAME_AR = ISNULL(@PRODUCT_NAME_AR, PRODUCT_NAME_AR),
            DESCRIPTION_EN = ISNULL(@DESCRIPTION_EN, DESCRIPTION_EN),
            DESCRIPTION_AR = ISNULL(@DESCRIPTION_AR, DESCRIPTION_AR),
            COUNTRY_OF_ORIGIN = ISNULL(@COUNTRY_OF_ORIGIN, COUNTRY_OF_ORIGIN),
            IS_HALAL_CERTIFIED = ISNULL(@IS_HALAL_CERTIFIED, IS_HALAL_CERTIFIED),
            HALAL_CERTIFICATE_NO = ISNULL(@HALAL_CERTIFICATE_NO, HALAL_CERTIFICATE_NO),
            HALAL_CERTIFICATE_URL = ISNULL(@HALAL_CERTIFICATE_URL, HALAL_CERTIFICATE_URL),
            NUTRITION_INFORMATION_EN = ISNULL(@NUTRITION_INFORMATION_EN, NUTRITION_INFORMATION_EN),
            NUTRITION_INFORMATION_AR = ISNULL(@NUTRITION_INFORMATION_AR, NUTRITION_INFORMATION_AR),
            STORAGE_INSTRUCTIONS_EN = ISNULL(@STORAGE_INSTRUCTIONS_EN, STORAGE_INSTRUCTIONS_EN),
            STORAGE_INSTRUCTIONS_AR = ISNULL(@STORAGE_INSTRUCTIONS_AR, STORAGE_INSTRUCTIONS_AR),
            IS_CUSTOMIZABLE = ISNULL(@IS_CUSTOMIZABLE, IS_CUSTOMIZABLE),
            CUSTOMIZATION_TEMPLATE_ID = ISNULL(@CUSTOMIZATION_TEMPLATE_ID, CUSTOMIZATION_TEMPLATE_ID),
            DISPLAY_ORDER = ISNULL(@DISPLAY_ORDER, DISPLAY_ORDER),
            IS_FEATURED = ISNULL(@IS_FEATURED, IS_FEATURED),
            IS_BESTSELLER = ISNULL(@IS_BESTSELLER, IS_BESTSELLER),
            IS_ACTIVE = ISNULL(@IS_ACTIVE, IS_ACTIVE),
            UPDATED_AT = SYSUTCDATETIME()
        WHERE PRODUCT_ID = @PRODUCT_ID;

        SELECT
            p.PRODUCT_ID AS ProductId, p.CATEGORY_ID AS CategoryId,
            c.CATEGORY_NAME_EN AS CategoryNameEn, p.DOC_NO AS DocNo, p.DOC_TYPE AS DocType,
            p.PRODUCT_NAME_EN AS ProductNameEn, p.PRODUCT_NAME_AR AS ProductNameAr,
            p.DESCRIPTION_EN AS DescriptionEn, p.DESCRIPTION_AR AS DescriptionAr,
            p.COUNTRY_OF_ORIGIN AS CountryOfOrigin,
            p.IS_HALAL_CERTIFIED AS IsHalalCertified, p.HALAL_CERTIFICATE_NO AS HalalCertificateNo,
            p.HALAL_CERTIFICATE_URL AS HalalCertificateUrl,
            p.NUTRITION_INFORMATION_EN AS NutritionInformationEn,
            p.NUTRITION_INFORMATION_AR AS NutritionInformationAr,
            p.STORAGE_INSTRUCTIONS_EN AS StorageInstructionsEn,
            p.STORAGE_INSTRUCTIONS_AR AS StorageInstructionsAr,
            p.IS_CUSTOMIZABLE AS IsCustomizable, p.CUSTOMIZATION_TEMPLATE_ID AS CustomizationTemplateId,
            p.DISPLAY_ORDER AS DisplayOrder, p.IS_FEATURED AS IsFeatured,
            p.IS_BESTSELLER AS IsBestseller, p.IS_ACTIVE AS IsActive,
            p.CREATED_AT AS CreatedAt, p.UPDATED_AT AS UpdatedAt
        FROM dbo.PRODUCTS p
        LEFT JOIN dbo.CATEGORIES c ON p.CATEGORY_ID = c.CATEGORY_ID
        WHERE p.PRODUCT_ID = @PRODUCT_ID;

        RETURN;
    END;

    -- =========================================================================
    -- MODE: DELETE
    -- =========================================================================
    IF @MODE = 'DELETE'
    BEGIN
        DELETE FROM dbo.PRODUCTS WHERE PRODUCT_ID = @PRODUCT_ID;
        SELECT @PRODUCT_ID AS ProductId;
        RETURN;
    END;
END;
GO
