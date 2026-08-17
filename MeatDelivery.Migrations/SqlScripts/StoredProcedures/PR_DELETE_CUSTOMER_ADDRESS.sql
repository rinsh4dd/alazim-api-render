-- =============================================================================
-- STORED PROCEDURE: dbo.PR_DELETE_CUSTOMER_ADDRESS
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_DELETE_CUSTOMER_ADDRESS
    @ADDRESS_ID BIGINT,
    @CUSTOMER_USER_ID BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.CUSTOMER_ADDRESSES
    SET IS_ACTIVE = 0,
        IS_DEFAULT = 0,
        UPDATED_AT = SYSUTCDATETIME()
    WHERE ADDRESS_ID = @ADDRESS_ID 
      AND CUSTOMER_USER_ID = @CUSTOMER_USER_ID;
END;
GO
