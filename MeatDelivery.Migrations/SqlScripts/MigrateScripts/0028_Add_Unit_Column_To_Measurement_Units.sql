-- =============================================================================
-- Migration: 0028_Add_Unit_Column_To_Measurement_Units.sql
-- Description: Adds UNIT column (e.g., 'Kg', 'g', 'Pcs', 'Pack') to dbo.MEASUREMENT_UNITS
--              and updates PR_GET_MEASUREMENT_UNITS & PR_SAVE_MEASUREMENT_UNIT.
-- =============================================================================

-- 1. ADD UNIT COLUMN IF NOT EXISTS
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.MEASUREMENT_UNITS') AND name = 'UNIT')
BEGIN
    ALTER TABLE dbo.MEASUREMENT_UNITS ADD UNIT VARCHAR(20) NULL;
END;
GO

-- 2. POPULATE INITIAL UNITS
UPDATE dbo.MEASUREMENT_UNITS SET UNIT = 'g' WHERE UNIT_DESCRIPTION = 'Gram' AND (UNIT IS NULL OR UNIT = '');
UPDATE dbo.MEASUREMENT_UNITS SET UNIT = 'Kg' WHERE UNIT_DESCRIPTION = 'Kilogram' AND (UNIT IS NULL OR UNIT = '');
UPDATE dbo.MEASUREMENT_UNITS SET UNIT = 'Pcs' WHERE UNIT_DESCRIPTION = 'Piece' AND (UNIT IS NULL OR UNIT = '');
UPDATE dbo.MEASUREMENT_UNITS SET UNIT = 'Pack' WHERE UNIT_DESCRIPTION = 'Pack' AND (UNIT IS NULL OR UNIT = '');
UPDATE dbo.MEASUREMENT_UNITS SET UNIT = UNIT_DESCRIPTION WHERE UNIT IS NULL;
GO

ALTER TABLE dbo.MEASUREMENT_UNITS ALTER COLUMN UNIT VARCHAR(20) NOT NULL;
GO

-- 3. UPDATE PR_GET_MEASUREMENT_UNITS
CREATE OR ALTER PROCEDURE dbo.PR_GET_MEASUREMENT_UNITS
    @ONLY_ACTIVE BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        UNIT_ID          AS UnitId,
        UNIT             AS Unit,
        UNIT_DESCRIPTION AS UnitDescription,
        IS_ACTIVE        AS IsActive
    FROM dbo.MEASUREMENT_UNITS
    WHERE (@ONLY_ACTIVE IS NULL OR IS_ACTIVE = @ONLY_ACTIVE)
    ORDER BY UNIT_ID ASC;
END;
GO

-- 4. UPDATE PR_SAVE_MEASUREMENT_UNIT
CREATE OR ALTER PROCEDURE dbo.PR_SAVE_MEASUREMENT_UNIT
    @MODE             VARCHAR(10),
    @UNIT_ID          INT = NULL,
    @UNIT             VARCHAR(20) = NULL,
    @UNIT_DESCRIPTION VARCHAR(50) = NULL,
    @IS_ACTIVE        BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @MODE = 'ADD'
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.MEASUREMENT_UNITS WHERE UNIT_DESCRIPTION = @UNIT_DESCRIPTION OR UNIT = @UNIT)
        BEGIN
            RAISERROR('Measurement unit or description already exists.', 16, 1);
            RETURN;
        END;

        INSERT INTO dbo.MEASUREMENT_UNITS (UNIT, UNIT_DESCRIPTION, IS_ACTIVE, CREATED_AT)
        VALUES (@UNIT, @UNIT_DESCRIPTION, ISNULL(@IS_ACTIVE, 1), SYSUTCDATETIME());

        SET @UNIT_ID = CAST(SCOPE_IDENTITY() AS INT);

        SELECT
            UNIT_ID          AS UnitId,
            UNIT             AS Unit,
            UNIT_DESCRIPTION AS UnitDescription,
            IS_ACTIVE        AS IsActive
        FROM dbo.MEASUREMENT_UNITS
        WHERE UNIT_ID = @UNIT_ID;

        RETURN;
    END;

    IF @MODE = 'EDIT'
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.MEASUREMENT_UNITS WHERE (UNIT_DESCRIPTION = @UNIT_DESCRIPTION OR UNIT = @UNIT) AND UNIT_ID <> @UNIT_ID)
        BEGIN
            RAISERROR('Measurement unit or description already exists.', 16, 1);
            RETURN;
        END;

        UPDATE dbo.MEASUREMENT_UNITS
        SET
            UNIT = ISNULL(@UNIT, UNIT),
            UNIT_DESCRIPTION = ISNULL(@UNIT_DESCRIPTION, UNIT_DESCRIPTION),
            IS_ACTIVE = ISNULL(@IS_ACTIVE, IS_ACTIVE)
        WHERE UNIT_ID = @UNIT_ID;

        SELECT
            UNIT_ID          AS UnitId,
            UNIT             AS Unit,
            UNIT_DESCRIPTION AS UnitDescription,
            IS_ACTIVE        AS IsActive
        FROM dbo.MEASUREMENT_UNITS
        WHERE UNIT_ID = @UNIT_ID;

        RETURN;
    END;
END;
GO
