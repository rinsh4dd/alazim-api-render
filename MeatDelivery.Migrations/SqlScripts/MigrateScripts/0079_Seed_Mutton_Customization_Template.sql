-- ============================================================================
-- Migration: 0079_Seed_Mutton_Customization_Template.sql
-- Description: Seeds Mutton & Meat Customization Template into dbo.CUSTOMIZATION_TEMPLATES,
--              maps all Customization Groups to it in dbo.TEMPLATE_GROUP_MAPPING,
--              and assigns Mutton, Lamb, Beef & Meat products to this template.
-- ============================================================================

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'CUSTOMIZATION_TEMPLATES' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    DECLARE @MuttonTemplateId BIGINT;

    -- 1. Check if Mutton template already exists or insert a new template
    SELECT @MuttonTemplateId = CUSTOMIZATION_TEMPLATE_ID 
    FROM dbo.CUSTOMIZATION_TEMPLATES 
    WHERE TEMPLATE_NAME_EN LIKE '%Mutton%' OR TEMPLATE_NAME_EN LIKE '%Meat%';

    IF @MuttonTemplateId IS NULL
    BEGIN
        DECLARE @DocNo VARCHAR(50);
        EXEC dbo.PR_GET_NEXT_DOC_NO @DOCTYPE = 'CTP1', @DOC_NO = @DocNo OUTPUT;
        IF @DocNo IS NULL OR @DocNo = '' SET @DocNo = 'CTP0000003';

        INSERT INTO dbo.CUSTOMIZATION_TEMPLATES
        (DOC_NO, DOC_TYPE, TEMPLATE_NAME_EN, TEMPLATE_NAME_AR, DESCRIPTION_EN, DESCRIPTION_AR, IS_ACTIVE, CREATED_AT)
        VALUES
        (@DocNo, 'CTP1', 'Mutton & Meat Customizations', N'تخصيصات الغنم واللحوم',
         'Standard cut, cleaning, marination, and packing options for mutton and meat products',
         N'خيارات التقطيع والتنظيف والتتبيل والتغليف المعتمدة لمنتجات الغنم واللحوم', 1, SYSUTCDATETIME());

        SET @MuttonTemplateId = SCOPE_IDENTITY();
    END

    -- 2. Map all Customization Groups to Mutton Template in TEMPLATE_GROUP_MAPPING
    IF @MuttonTemplateId IS NOT NULL
    BEGIN
        INSERT INTO dbo.TEMPLATE_GROUP_MAPPING (CUSTOMIZATION_TEMPLATE_ID, CUSTOMIZATION_GROUP_ID, CREATED_AT)
        SELECT @MuttonTemplateId, cg.CUSTOMIZATION_GROUP_ID, SYSUTCDATETIME()
        FROM dbo.CUSTOMIZATION_GROUPS cg
        WHERE NOT EXISTS (
            SELECT 1 FROM dbo.TEMPLATE_GROUP_MAPPING tgm 
            WHERE tgm.CUSTOMIZATION_TEMPLATE_ID = @MuttonTemplateId 
              AND tgm.CUSTOMIZATION_GROUP_ID = cg.CUSTOMIZATION_GROUP_ID
        );

        -- 3. Map Mutton/Beef/Lamb/Meat/Steak products to Mutton Template
        UPDATE p
        SET p.CUSTOMIZATION_TEMPLATE_ID = @MuttonTemplateId,
            p.IS_CUSTOMIZABLE = 1
        FROM dbo.PRODUCTS p
        LEFT JOIN dbo.CATEGORIES c ON c.CATEGORY_ID = p.CATEGORY_ID
        WHERE (p.CUSTOMIZATION_TEMPLATE_ID IS NULL OR p.CUSTOMIZATION_TEMPLATE_ID <> 2)
          AND (c.CATEGORY_CODE IN ('MUTTON', 'BEEF', 'LAMB') 
               OR p.PRODUCT_NAME_EN LIKE '%Mutton%' 
               OR p.PRODUCT_NAME_EN LIKE '%Lamb%' 
               OR p.PRODUCT_NAME_EN LIKE '%Beef%' 
               OR p.PRODUCT_NAME_EN LIKE '%Steak%' 
               OR p.PRODUCT_NAME_AR LIKE '%لحم%' 
               OR p.PRODUCT_NAME_AR LIKE '%غنم%' 
               OR p.PRODUCT_NAME_AR LIKE '%ستيك%'
               OR c.CATEGORY_CODE IS NOT NULL);
    END
END
GO
