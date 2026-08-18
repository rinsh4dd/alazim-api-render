-- =============================================================================
-- Migration: 0040_Drop_PR_CLEAR_PRODUCT_CHILDREN.sql
-- Description: Drops unused stored procedure PR_CLEAR_PRODUCT_CHILDREN.
-- =============================================================================

IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('dbo.PR_CLEAR_PRODUCT_CHILDREN') AND type = 'P')
BEGIN
    DROP PROCEDURE dbo.PR_CLEAR_PRODUCT_CHILDREN;
END;
GO
