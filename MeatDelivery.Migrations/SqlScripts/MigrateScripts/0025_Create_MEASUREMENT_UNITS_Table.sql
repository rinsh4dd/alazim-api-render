-- =============================================================================
-- Migration: 0025_Create_MEASUREMENT_UNITS_Table.sql
-- Description: Creates dbo.MEASUREMENT_UNITS table and seeds initial units
--              (Gram, Kilogram, Piece, Pack).
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID('dbo.MEASUREMENT_UNITS'))
BEGIN
    CREATE TABLE dbo.MEASUREMENT_UNITS
    (
        UNIT_ID             INT IDENTITY(1,1) NOT NULL,
        UNIT_DESCRIPTION    VARCHAR(50) NOT NULL,
        IS_ACTIVE           BIT NOT NULL DEFAULT 1,
        CREATED_AT          DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

        CONSTRAINT PK_MEASUREMENT_UNITS PRIMARY KEY CLUSTERED (UNIT_ID),
        CONSTRAINT UQ_MEASUREMENT_UNITS_DESCRIPTION UNIQUE NONCLUSTERED (UNIT_DESCRIPTION)
    );

    -- Seed initial measurement units from Notion specification
    INSERT INTO dbo.MEASUREMENT_UNITS (UNIT_DESCRIPTION, IS_ACTIVE)
    VALUES 
        ('Gram', 1),
        ('Kilogram', 1),
        ('Piece', 1),
        ('Pack', 1);
END;
GO
