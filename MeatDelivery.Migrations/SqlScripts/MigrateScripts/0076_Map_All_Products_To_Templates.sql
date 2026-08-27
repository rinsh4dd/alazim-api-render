-- ============================================================================
-- Migration: 0076_Map_All_Products_To_Templates.sql
-- Description: Ensures ALL products in dbo.PRODUCTS have a customization template assigned
-- ============================================================================

-- 1. Map Chicken products to Template 2 (Chicken Customizations)
UPDATE dbo.PRODUCTS
SET CUSTOMIZATION_TEMPLATE_ID = 2,
    IS_CUSTOMIZABLE = 1
WHERE (PRODUCT_NAME_EN LIKE '%Chicken%' OR PRODUCT_NAME_AR LIKE '%دجاج%')
  AND EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_TEMPLATES WHERE CUSTOMIZATION_TEMPLATE_ID = 2);

-- 2. Map all remaining products to Template 3 (Mutton & Meat Customizations)
UPDATE dbo.PRODUCTS
SET CUSTOMIZATION_TEMPLATE_ID = 3,
    IS_CUSTOMIZABLE = 1
WHERE CUSTOMIZATION_TEMPLATE_ID IS NULL
  AND EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_TEMPLATES WHERE CUSTOMIZATION_TEMPLATE_ID = 3);
