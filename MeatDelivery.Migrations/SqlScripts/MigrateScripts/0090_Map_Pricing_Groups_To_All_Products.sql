-- Migration Script: 0090_Map_Pricing_Groups_To_All_Products.sql
-- Description: Assign active customization template to all products and map all pricing groups to active templates.

-- 1. Get first active Customization Template ID
DECLARE @DefaultTemplateId BIGINT = (SELECT TOP 1 CUSTOMIZATION_TEMPLATE_ID FROM dbo.CUSTOMIZATION_TEMPLATES WHERE IS_ACTIVE = 1 ORDER BY CUSTOMIZATION_TEMPLATE_ID ASC);

-- If no active template exists, create default 'Standard Meat Customization' template
IF @DefaultTemplateId IS NULL
BEGIN
    INSERT INTO dbo.CUSTOMIZATION_TEMPLATES (DOC_NO, TEMPLATE_NAME_EN, TEMPLATE_NAME_AR, DESCRIPTION_EN, DESCRIPTION_AR, IS_ACTIVE, CREATED_AT)
    VALUES ('TMP000001', 'Standard Meat Customization', N'تخصيص اللحوم القياسي', 'Default customization template', N'قالب التخصيص الافتراضي', 1, SYSUTCDATETIME());

    SET @DefaultTemplateId = SCOPE_IDENTITY();
END;

-- 2. Assign default template to all active products that don't have one
UPDATE dbo.PRODUCTS
SET IS_CUSTOMIZABLE = 1,
    CUSTOMIZATION_TEMPLATE_ID = @DefaultTemplateId,
    UPDATED_AT = SYSUTCDATETIME()
WHERE (CUSTOMIZATION_TEMPLATE_ID IS NULL OR CUSTOMIZATION_TEMPLATE_ID <= 0)
  AND (IS_DELETED = 0 OR IS_DELETED IS NULL);
GO

-- 3. Map all active Customization Groups to all active templates
INSERT INTO dbo.TEMPLATE_GROUP_MAPPING (CUSTOMIZATION_TEMPLATE_ID, CUSTOMIZATION_GROUP_ID, IS_ACTIVE, CREATED_AT)
SELECT t.CUSTOMIZATION_TEMPLATE_ID, cg.CUSTOMIZATION_GROUP_ID, 1, SYSUTCDATETIME()
FROM dbo.CUSTOMIZATION_TEMPLATES t
CROSS JOIN dbo.CUSTOMIZATION_GROUPS cg
WHERE t.IS_ACTIVE = 1 AND cg.IS_ACTIVE = 1
  AND NOT EXISTS (
      SELECT 1 FROM dbo.TEMPLATE_GROUP_MAPPING m
      WHERE m.CUSTOMIZATION_TEMPLATE_ID = t.CUSTOMIZATION_TEMPLATE_ID 
        AND m.CUSTOMIZATION_GROUP_ID = cg.CUSTOMIZATION_GROUP_ID
  );
GO
