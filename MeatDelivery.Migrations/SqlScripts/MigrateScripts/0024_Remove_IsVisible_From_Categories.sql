-- =============================================================================
-- Migration: 0024_Remove_IsVisible_From_Categories.sql
-- Description: Safely drops dependent indexes and default constraints before
--              dropping IS_VISIBLE column from dbo.CATEGORIES.
-- =============================================================================

-- 1. Drop dependent index if exists
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CATEGORIES_DISPLAY_ORDER' AND object_id = OBJECT_ID('dbo.CATEGORIES'))
BEGIN
    DROP INDEX IX_CATEGORIES_DISPLAY_ORDER ON dbo.CATEGORIES;
END;
GO

-- 2. Drop default constraint on IS_VISIBLE dynamically
DECLARE @ConstraintName NVARCHAR(200);
SELECT @ConstraintName = dc.name
FROM sys.default_constraints dc
JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
WHERE dc.parent_object_id = OBJECT_ID('dbo.CATEGORIES')
  AND c.name = 'IS_VISIBLE';

IF @ConstraintName IS NOT NULL
BEGIN
    EXEC('ALTER TABLE dbo.CATEGORIES DROP CONSTRAINT ' + @ConstraintName);
END;
GO

-- 3. Drop column IS_VISIBLE
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.CATEGORIES') AND name = 'IS_VISIBLE')
BEGIN
    ALTER TABLE dbo.CATEGORIES DROP COLUMN IS_VISIBLE;
END;
GO

-- 4. Re-create IX_CATEGORIES_DISPLAY_ORDER index without IS_VISIBLE
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CATEGORIES_DISPLAY_ORDER' AND object_id = OBJECT_ID('dbo.CATEGORIES'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_CATEGORIES_DISPLAY_ORDER 
        ON dbo.CATEGORIES (DISPLAY_ORDER, IS_ACTIVE);
END;
GO
