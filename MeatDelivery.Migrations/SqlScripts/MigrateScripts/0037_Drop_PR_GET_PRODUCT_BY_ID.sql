-- =============================================================================
-- Migration: 0037_Drop_PR_GET_PRODUCT_BY_ID.sql
-- Description: Drops stored procedure PR_GET_PRODUCT_BY_ID.
-- =============================================================================

IF EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('dbo.PR_GET_PRODUCT_BY_ID') AND type = 'P')
BEGIN
    DROP PROCEDURE dbo.PR_GET_PRODUCT_BY_ID;
END;
GO
