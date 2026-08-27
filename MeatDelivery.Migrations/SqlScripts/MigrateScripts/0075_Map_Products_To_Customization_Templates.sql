-- ============================================================================
-- Migration: 0075_Map_Products_To_Customization_Templates.sql
-- Description: Maps active products to customization templates in dbo.PRODUCTS
-- ============================================================================

-- 1. Map Chicken Category & Chicken Products to Chicken Customization Template (ID 2)
UPDATE p
SET p.CUSTOMIZATION_TEMPLATE_ID = 2,
    p.IS_CUSTOMIZABLE = 1
FROM dbo.PRODUCTS p
LEFT JOIN dbo.CATEGORIES c ON c.CATEGORY_ID = p.CATEGORY_ID
WHERE (c.CATEGORY_CODE = 'CHICKEN' OR p.PRODUCT_NAME_EN LIKE '%Chicken%' OR p.PRODUCT_NAME_AR LIKE '%دجاج%')
  AND EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_TEMPLATES ct WHERE ct.CUSTOMIZATION_TEMPLATE_ID = 2);

-- 2. Map Mutton / Beef / Lamb / Steak Products to Mutton/Meat Customization Template (ID 3)
UPDATE p
SET p.CUSTOMIZATION_TEMPLATE_ID = 3,
    p.IS_CUSTOMIZABLE = 1
FROM dbo.PRODUCTS p
LEFT JOIN dbo.CATEGORIES c ON c.CATEGORY_ID = p.CATEGORY_ID
WHERE (c.CATEGORY_CODE IN ('MUTTON', 'BEEF') OR p.PRODUCT_NAME_EN LIKE '%Mutton%' OR p.PRODUCT_NAME_EN LIKE '%Steak%' OR p.PRODUCT_NAME_EN LIKE '%Lamb%' OR p.PRODUCT_NAME_EN LIKE '%Beef%' OR p.PRODUCT_NAME_AR LIKE '%لحم%' OR p.PRODUCT_NAME_AR LIKE '%ستيك%')
  AND EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_TEMPLATES ct WHERE ct.CUSTOMIZATION_TEMPLATE_ID = 3);
