-- =============================================================================
-- TABLE: dbo.MEASUREMENT_UNITS
-- Description: Master lookup table for product weight & size measurement units.
-- Initial Units: Gram, Kilogram, Piece, Pack
-- =============================================================================

CREATE TABLE dbo.MEASUREMENT_UNITS
(
    UNIT_ID             INT IDENTITY(1,1) NOT NULL,
    UNIT_DESCRIPTION    VARCHAR(50) NOT NULL,
    IS_ACTIVE           BIT NOT NULL DEFAULT 1,
    CREATED_AT          DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_MEASUREMENT_UNITS PRIMARY KEY CLUSTERED (UNIT_ID),
    CONSTRAINT UQ_MEASUREMENT_UNITS_DESCRIPTION UNIQUE NONCLUSTERED (UNIT_DESCRIPTION)
);
GO
