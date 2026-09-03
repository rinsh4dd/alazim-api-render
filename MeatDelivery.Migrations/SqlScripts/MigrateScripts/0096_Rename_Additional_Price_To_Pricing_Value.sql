-- Migration Script: 0096_Rename_Additional_Price_To_Pricing_Value.sql
-- Description: Rename column ADDITIONAL_PRICE to PRICING_VALUE in dbo.CUSTOMIZATION_OPTIONS table.

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.CUSTOMIZATION_OPTIONS') AND name = 'ADDITIONAL_PRICE')
BEGIN
    EXEC sp_rename 'dbo.CUSTOMIZATION_OPTIONS.ADDITIONAL_PRICE', 'PRICING_VALUE', 'COLUMN';
END;
GO
