-- =============================================================================
-- STORED PROCEDURE: dbo.PR_GET_CUSTOMER_ADDRESS
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_GET_CUSTOMER_ADDRESS
    @ADDRESS_ID BIGINT = NULL,
    @CUSTOMER_USER_ID BIGINT = NULL,
    @ADDRESS_TYPE VARCHAR(20) = NULL,
    @IS_DEFAULT BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        ADDRESS_ID AS AddressId,
        CUSTOMER_USER_ID AS CustomerUserId,
        FIRST_NAME AS FirstName,
        LAST_NAME AS LastName,
        ADDRESS_TYPE AS AddressType,
        CONTACT_NUMBER AS ContactNumber,
        BUILDING_NAME AS BuildingName,
        VILLA_OR_FLAT_NO AS VillaOrFlatNo,
        STREET AS Street,
        AREA AS Area,
        LANDMARK AS Landmark,
        CITY AS City,
        STATE AS State,
        POSTAL_CODE AS PostalCode,
        LATITUDE AS Latitude,
        LONGITUDE AS Longitude,
        IS_DEFAULT AS IsDefault,
        IS_ACTIVE AS IsActive,
        CREATED_AT AS CreatedAt,
        UPDATED_AT AS UpdatedAt
    FROM dbo.CUSTOMER_ADDRESSES
    WHERE (@ADDRESS_ID IS NULL OR ADDRESS_ID = @ADDRESS_ID)
      AND (@CUSTOMER_USER_ID IS NULL OR CUSTOMER_USER_ID = @CUSTOMER_USER_ID)
      AND (@ADDRESS_TYPE IS NULL OR ADDRESS_TYPE = @ADDRESS_TYPE)
      AND (@IS_DEFAULT IS NULL OR IS_DEFAULT = @IS_DEFAULT)
      AND IS_ACTIVE = 1
    ORDER BY IS_DEFAULT DESC, CREATED_AT DESC;
END;
GO
