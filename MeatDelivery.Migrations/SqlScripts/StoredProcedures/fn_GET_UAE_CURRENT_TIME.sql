-- =============================================================================
-- FUNCTION: dbo.fn_GET_UAE_CURRENT_TIME
-- Description: Returns current UAE local time (Gulf Standard Time, UTC + 4 hours).
-- =============================================================================

CREATE OR ALTER FUNCTION dbo.fn_GET_UAE_CURRENT_TIME()
RETURNS DATETIME2
AS
BEGIN
    RETURN DATEADD(HOUR, 4, SYSUTCDATETIME());
END;
GO
