-- Migration Script: 0100_Drop_Custom_Data_From_Cart_Items.sql
-- Description: Drop unused CUSTOM_DATA column from dbo.CART_ITEMS table safely.

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.CART_ITEMS') AND name = 'CUSTOM_DATA')
BEGIN
    -- Drop any DEFAULT constraints bound to CUSTOM_DATA column
    DECLARE @ConstraintName NVARCHAR(200);
    SELECT @ConstraintName = name
    FROM sys.default_constraints
    WHERE parent_object_id = OBJECT_ID(N'dbo.CART_ITEMS')
      AND parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'dbo.CART_ITEMS'), 'CUSTOM_DATA', 'ColumnId');

    IF @ConstraintName IS NOT NULL
    BEGIN
        EXEC('ALTER TABLE dbo.CART_ITEMS DROP CONSTRAINT [' + @ConstraintName + '];');
    END;

    -- Drop CUSTOM_DATA column
    ALTER TABLE dbo.CART_ITEMS
    DROP COLUMN CUSTOM_DATA;
END;
GO
