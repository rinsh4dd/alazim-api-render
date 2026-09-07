-- =============================================================================
-- Migration: 0114_Add_AdvanceDeliveryDays_To_COMPANY_CONFIG.sql
-- Description: Adds ADVANCE_DELIVERY_DAYS column to dbo.COMPANY_CONFIG table.
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') AND name = 'ADVANCE_DELIVERY_DAYS')
BEGIN
    ALTER TABLE dbo.COMPANY_CONFIG 
    ADD ADVANCE_DELIVERY_DAYS INT NOT NULL DEFAULT 30;
END
GO
