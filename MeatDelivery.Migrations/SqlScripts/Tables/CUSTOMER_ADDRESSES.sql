-- =============================================================================
-- TABLE: dbo.CUSTOMER_ADDRESSES
-- Description: Stores customer delivery and billing addresses.
-- =============================================================================

CREATE TABLE dbo.CUSTOMER_ADDRESSES
(
    ADDRESS_ID         BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CUSTOMER_USER_ID   BIGINT               NOT NULL,
    FIRST_NAME         NVARCHAR(100)        NULL,
    LAST_NAME          NVARCHAR(100)        NULL,
    ADDRESS_TYPE       VARCHAR(20)          NOT NULL,
    CONTACT_NUMBER     VARCHAR(20)          NOT NULL,
    BUILDING_NAME      NVARCHAR(150)        NULL,
    VILLA_OR_FLAT_NO   NVARCHAR(50)         NULL,
    STREET             NVARCHAR(200)        NULL,
    AREA               NVARCHAR(100)        NULL,
    LANDMARK           NVARCHAR(200)        NULL,
    CITY               NVARCHAR(100)        NOT NULL,
    STATE              NVARCHAR(100)        NULL,
    POSTAL_CODE        VARCHAR(20)          NULL,
    LATITUDE           DECIMAL(10, 7)       NULL,
    LONGITUDE          DECIMAL(10, 7)       NULL,
    IS_DEFAULT         BIT                  NOT NULL DEFAULT 0,
    IS_ACTIVE          BIT                  NOT NULL DEFAULT 1,
    CREATED_AT         DATETIME2            NOT NULL DEFAULT SYSUTCDATETIME(),
    UPDATED_AT         DATETIME2            NULL,
    CONSTRAINT FK_CUSTOMER_ADDRESSES_USER FOREIGN KEY (CUSTOMER_USER_ID) REFERENCES dbo.CUSTOMER_USERS(USER_ID)
);

CREATE NONCLUSTERED INDEX IX_CUSTOMER_ADDRESSES_USER_ACTIVE 
ON dbo.CUSTOMER_ADDRESSES(CUSTOMER_USER_ID, IS_ACTIVE);
GO
