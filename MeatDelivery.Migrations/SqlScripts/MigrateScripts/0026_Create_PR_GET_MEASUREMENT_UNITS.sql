-- =============================================================================
-- Migration: 0026_Create_PR_GET_MEASUREMENT_UNITS.sql
-- Description: Creates stored procedure dbo.PR_GET_MEASUREMENT_UNITS.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_GET_MEASUREMENT_UNITS
    @ONLY_ACTIVE BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        UNIT_ID          AS UnitId,
        UNIT_DESCRIPTION AS UnitDescription,
        IS_ACTIVE        AS IsActive
    FROM dbo.MEASUREMENT_UNITS
    WHERE (@ONLY_ACTIVE IS NULL OR IS_ACTIVE = @ONLY_ACTIVE)
    ORDER BY UNIT_ID ASC;
END;
GO
