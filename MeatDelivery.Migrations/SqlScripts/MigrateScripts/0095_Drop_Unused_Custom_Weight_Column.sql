-- Migration Script: 0095_Drop_Unused_Custom_Weight_Column.sql
-- Description: Drop unused CUSTOM_WEIGHT column from dbo.CART_ITEMS as we use generic CUSTOM_DATA column.

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.CART_ITEMS') AND name = 'CUSTOM_WEIGHT')
BEGIN
    ALTER TABLE dbo.CART_ITEMS
    DROP COLUMN CUSTOM_WEIGHT;
END;
GO
