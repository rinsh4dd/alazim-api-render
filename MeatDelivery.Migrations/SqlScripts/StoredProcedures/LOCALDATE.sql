-- =============================================================================
-- FUNCTION: dbo.LOCALDATE
-- Description: Company local date calculation (UTC + 4 hours for UAE / Dubai).
-- =============================================================================

CREATE OR ALTER FUNCTION dbo.LOCALDATE()
RETURNS DATETIME2
AS
BEGIN
    RETURN DATEADD(MINUTE, 240, SYSUTCDATETIME());
END;
GO
