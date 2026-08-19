-- =============================================================================
-- TABLE: dbo.PRODUCT_PRICES
-- Description: Product price tracking linked directly to PRODUCT_ID.
-- =============================================================================

CREATE TABLE dbo.PRODUCT_PRICES
(
    PRICE_ID            BIGINT IDENTITY(1,1) NOT NULL,
    PRODUCT_ID          BIGINT NOT NULL,
    PRICE               DECIMAL(18,2) NOT NULL,
    IS_ACTIVE           BIT NOT NULL DEFAULT 1,
    CREATED_AT          DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UPDATED_AT          DATETIME2 NULL,

    CONSTRAINT PK_PRODUCT_PRICES PRIMARY KEY CLUSTERED (PRICE_ID),
    CONSTRAINT FK_PRODUCT_PRICES_PRODUCT FOREIGN KEY (PRODUCT_ID) 
        REFERENCES dbo.PRODUCTS (PRODUCT_ID) ON DELETE CASCADE
);

CREATE NONCLUSTERED INDEX IX_PRODUCT_PRICES_PRODUCT 
    ON dbo.PRODUCT_PRICES (PRODUCT_ID, IS_ACTIVE);
GO
