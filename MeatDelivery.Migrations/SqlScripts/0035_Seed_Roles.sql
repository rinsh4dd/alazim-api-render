-- Migration 0035: Seed Initial Roles
MERGE INTO dbo.ROLES AS Target
USING (VALUES 
    ('CUSTOMER', 'Customer', 'End user customer account'),
    ('SUPER_ADMIN', 'Super Admin', 'Full system super administrator'),
    ('ADMINISTRATOR', 'Administrator', 'System administrator'),
    ('INVENTORY_MANAGER', 'Inventory Manager', 'Manages product catalog and inventory stock'),
    ('ORDER_MANAGER', 'Order Manager', 'Manages orders and delivery fulfillment'),
    ('CUSTOMER_SUPPORT', 'Customer Support', 'Handles customer queries and support issues')
) AS Source (ROLE_CODE, ROLE_NAME, DESCRIPTION)
ON Target.ROLE_CODE = Source.ROLE_CODE
WHEN NOT MATCHED THEN
    INSERT (ROLE_CODE, ROLE_NAME, DESCRIPTION, IS_ACTIVE, CREATED_AT)
    VALUES (Source.ROLE_CODE, Source.ROLE_NAME, Source.DESCRIPTION, 1, SYSUTCDATETIME());
