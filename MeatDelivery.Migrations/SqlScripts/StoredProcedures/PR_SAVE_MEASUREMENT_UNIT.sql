-- =============================================================================
-- STORED PROCEDURE: dbo.PR_SAVE_MEASUREMENT_UNIT
-- Description: Creates or updates a measurement unit (ADD and EDIT modes).
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_SAVE_MEASUREMENT_UNIT
    @MODE             VARCHAR(10),
    @UNIT_ID          INT = NULL,
    @UNIT_DESCRIPTION VARCHAR(50) = NULL,
    @IS_ACTIVE        BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @MODE = 'ADD'
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.MEASUREMENT_UNITS WHERE UNIT_DESCRIPTION = @UNIT_DESCRIPTION)
        BEGIN
            RAISERROR('Measurement unit description already exists.', 16, 1);
            RETURN;
        END;

        INSERT INTO dbo.MEASUREMENT_UNITS (UNIT_DESCRIPTION, IS_ACTIVE, CREATED_AT)
        VALUES (@UNIT_DESCRIPTION, ISNULL(@IS_ACTIVE, 1), SYSUTCDATETIME());

        SET @UNIT_ID = CAST(SCOPE_IDENTITY() AS INT);

        SELECT
            UNIT_ID          AS UnitId,
            UNIT_DESCRIPTION AS UnitDescription,
            IS_ACTIVE        AS IsActive
        FROM dbo.MEASUREMENT_UNITS
        WHERE UNIT_ID = @UNIT_ID;

        RETURN;
    END;

    IF @MODE = 'EDIT'
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.MEASUREMENT_UNITS WHERE UNIT_DESCRIPTION = @UNIT_DESCRIPTION AND UNIT_ID <> @UNIT_ID)
        BEGIN
            RAISERROR('Measurement unit description already exists.', 16, 1);
            RETURN;
        END;

        UPDATE dbo.MEASUREMENT_UNITS
        SET
            UNIT_DESCRIPTION = ISNULL(@UNIT_DESCRIPTION, UNIT_DESCRIPTION),
            IS_ACTIVE = ISNULL(@IS_ACTIVE, IS_ACTIVE)
        WHERE UNIT_ID = @UNIT_ID;

        SELECT
            UNIT_ID          AS UnitId,
            UNIT_DESCRIPTION AS UnitDescription,
            IS_ACTIVE        AS IsActive
        FROM dbo.MEASUREMENT_UNITS
        WHERE UNIT_ID = @UNIT_ID;

        RETURN;
    END;
END;
GO
