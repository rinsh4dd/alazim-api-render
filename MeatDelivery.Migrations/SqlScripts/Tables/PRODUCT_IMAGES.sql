-- =============================================================================
-- TABLE: dbo.PRODUCT_IMAGES
-- Description: 1:1 image storage per product (Primary, Secondary, Tertiary URLs).
-- =============================================================================

CREATE TABLE dbo.PRODUCT_IMAGES
(
    IMAGE_ID            BIGINT IDENTITY(1,1) NOT NULL,
    PRODUCT_ID          BIGINT NOT NULL,
    PRIMARY_URL         VARCHAR(500) NOT NULL,
    SECONDARY_URL       VARCHAR(500) NULL,
    TERTIARY_URL        VARCHAR(500) NULL,

    CONSTRAINT PK_PRODUCT_IMAGES PRIMARY KEY CLUSTERED (IMAGE_ID),
    CONSTRAINT FK_PRODUCT_IMAGES_PRODUCT FOREIGN KEY (PRODUCT_ID) 
        REFERENCES dbo.PRODUCTS (PRODUCT_ID) ON DELETE CASCADE,
    CONSTRAINT UQ_PRODUCT_IMAGES_PRODUCT UNIQUE NONCLUSTERED (PRODUCT_ID)
);
GO
