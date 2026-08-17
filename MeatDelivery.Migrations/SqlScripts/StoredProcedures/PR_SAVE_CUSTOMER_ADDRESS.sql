-- =============================================================================
-- STORED PROCEDURE: dbo.PR_SAVE_CUSTOMER_ADDRESS
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_SAVE_CUSTOMER_ADDRESS
    @MODE VARCHAR(10),
    @ADDRESS_ID BIGINT = NULL,
    @CUSTOMER_USER_ID BIGINT,
    @FIRST_NAME NVARCHAR(100) = NULL,
    @LAST_NAME NVARCHAR(100) = NULL,
    @ADDRESS_TYPE VARCHAR(20),
    @CONTACT_NUMBER VARCHAR(20),
    @BUILDING_NAME NVARCHAR(150) = NULL,
    @VILLA_OR_FLAT_NO NVARCHAR(50) = NULL,
    @STREET NVARCHAR(200) = NULL,
    @AREA NVARCHAR(100) = NULL,
    @LANDMARK NVARCHAR(200) = NULL,
    @CITY NVARCHAR(100),
    @STATE NVARCHAR(100) = NULL,
    @POSTAL_CODE VARCHAR(20) = NULL,
    @LATITUDE DECIMAL(10, 7) = NULL,
    @LONGITUDE DECIMAL(10, 7) = NULL,
    @IS_DEFAULT BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @MODE = 'ADD'
    BEGIN
        IF @IS_DEFAULT = 1
        BEGIN
            UPDATE dbo.CUSTOMER_ADDRESSES
            SET IS_DEFAULT = 0, UPDATED_AT = SYSUTCDATETIME()
            WHERE CUSTOMER_USER_ID = @CUSTOMER_USER_ID;
        END

        INSERT INTO dbo.CUSTOMER_ADDRESSES
        (
            CUSTOMER_USER_ID,
            FIRST_NAME,
            LAST_NAME,
            ADDRESS_TYPE,
            CONTACT_NUMBER,
            BUILDING_NAME,
            VILLA_OR_FLAT_NO,
            STREET,
            AREA,
            LANDMARK,
            CITY,
            STATE,
            POSTAL_CODE,
            LATITUDE,
            LONGITUDE,
            IS_DEFAULT,
            IS_ACTIVE,
            CREATED_AT
        )
        VALUES
        (
            @CUSTOMER_USER_ID,
            @FIRST_NAME,
            @LAST_NAME,
            @ADDRESS_TYPE,
            @CONTACT_NUMBER,
            @BUILDING_NAME,
            @VILLA_OR_FLAT_NO,
            @STREET,
            @AREA,
            @LANDMARK,
            @CITY,
            @STATE,
            @POSTAL_CODE,
            @LATITUDE,
            @LONGITUDE,
            @IS_DEFAULT,
            1,
            SYSUTCDATETIME()
        );

        SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS AddressId;
    END
    ELSE IF @MODE = 'UPDATE'
    BEGIN
        IF @ADDRESS_ID IS NULL
        BEGIN
            RAISERROR('ADDRESS_ID is required for UPDATE mode.', 16, 1);
            RETURN;
        END

        IF @IS_DEFAULT = 1
        BEGIN
            UPDATE dbo.CUSTOMER_ADDRESSES
            SET IS_DEFAULT = 0, UPDATED_AT = SYSUTCDATETIME()
            WHERE CUSTOMER_USER_ID = @CUSTOMER_USER_ID;
        END

        UPDATE dbo.CUSTOMER_ADDRESSES
        SET FIRST_NAME = ISNULL(@FIRST_NAME, FIRST_NAME),
            LAST_NAME = ISNULL(@LAST_NAME, LAST_NAME),
            ADDRESS_TYPE = ISNULL(@ADDRESS_TYPE, ADDRESS_TYPE),
            CONTACT_NUMBER = ISNULL(@CONTACT_NUMBER, CONTACT_NUMBER),
            BUILDING_NAME = ISNULL(@BUILDING_NAME, BUILDING_NAME),
            VILLA_OR_FLAT_NO = ISNULL(@VILLA_OR_FLAT_NO, VILLA_OR_FLAT_NO),
            STREET = ISNULL(@STREET, STREET),
            AREA = ISNULL(@AREA, AREA),
            LANDMARK = ISNULL(@LANDMARK, LANDMARK),
            CITY = ISNULL(@CITY, CITY),
            STATE = ISNULL(@STATE, STATE),
            POSTAL_CODE = ISNULL(@POSTAL_CODE, POSTAL_CODE),
            LATITUDE = ISNULL(@LATITUDE, LATITUDE),
            LONGITUDE = ISNULL(@LONGITUDE, LONGITUDE),
            IS_DEFAULT = ISNULL(@IS_DEFAULT, IS_DEFAULT),
            UPDATED_AT = SYSUTCDATETIME()
        WHERE ADDRESS_ID = @ADDRESS_ID 
          AND CUSTOMER_USER_ID = @CUSTOMER_USER_ID;

        SELECT @ADDRESS_ID AS AddressId;
    END
END;
GO
