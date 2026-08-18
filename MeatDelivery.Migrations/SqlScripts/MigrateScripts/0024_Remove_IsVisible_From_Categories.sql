-- =============================================================================
-- Migration: 0024_Remove_IsVisible_From_Categories.sql
-- Description: Removes IS_VISIBLE column from dbo.CATEGORIES
--              and updates PR_SAVE_CATEGORY procedure.
-- =============================================================================

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.CATEGORIES') AND name = 'IS_VISIBLE')
BEGIN
    ALTER TABLE dbo.CATEGORIES DROP COLUMN IS_VISIBLE;
END;
GO
