-- Migration: 0064_Remove_DisplayOrder_From_CustomizationGroups.sql
-- Description: Safely drops index, default constraint, and DISPLAY_ORDER column from dbo.CUSTOMIZATION_GROUPS.

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.CUSTOMIZATION_GROUPS') AND name = 'DISPLAY_ORDER')
BEGIN
    -- 1. Drop Index referencing DISPLAY_ORDER if present
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.CUSTOMIZATION_GROUPS') AND name = 'IX_CUSTOMIZATION_GROUPS_DISPLAY')
    BEGIN
        DROP INDEX IX_CUSTOMIZATION_GROUPS_DISPLAY ON dbo.CUSTOMIZATION_GROUPS;
    END;

    -- 2. Drop Default Constraint on DISPLAY_ORDER if present
    DECLARE @ConstraintName NVARCHAR(200);
    SELECT @ConstraintName = dc.name
    FROM sys.default_constraints dc
    JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
    WHERE dc.parent_object_id = OBJECT_ID('dbo.CUSTOMIZATION_GROUPS')
      AND c.name = 'DISPLAY_ORDER';

    IF @ConstraintName IS NOT NULL
    BEGIN
        EXEC('ALTER TABLE dbo.CUSTOMIZATION_GROUPS DROP CONSTRAINT [' + @ConstraintName + '];');
    END;

    -- 3. Drop Column DISPLAY_ORDER
    ALTER TABLE dbo.CUSTOMIZATION_GROUPS DROP COLUMN DISPLAY_ORDER;

    -- 4. Create Active Index if not present
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.CUSTOMIZATION_GROUPS') AND name = 'IX_CUSTOMIZATION_GROUPS_ACTIVE')
    BEGIN
        CREATE NONCLUSTERED INDEX IX_CUSTOMIZATION_GROUPS_ACTIVE 
            ON dbo.CUSTOMIZATION_GROUPS (IS_ACTIVE);
    END;
END;
GO
