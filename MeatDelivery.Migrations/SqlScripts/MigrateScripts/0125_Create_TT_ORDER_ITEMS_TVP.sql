-- =============================================================================
-- MIGRATION SCRIPT: 0125_Create_TT_ORDER_ITEMS_TVP.sql
-- Description: Creates TT_ORDER_ITEMS and TT_ORDER_ITEM_CUSTOMIZATIONS Table-Valued Parameters
-- =============================================================================

IF NOT EXISTS (SELECT * FROM sys.types WHERE is_table_type = 1 AND name = 'TT_ORDER_ITEMS')
BEGIN
    CREATE TYPE dbo.TT_ORDER_ITEMS AS TABLE
    (
        ItemTempId               INT NOT NULL,
        ProductId                BIGINT NOT NULL,
        ProductCode              VARCHAR(50) NULL,
        ProductNameEn            NVARCHAR(200) NOT NULL,
        ProductNameAr            NVARCHAR(200) NOT NULL,
        UnitDescription         VARCHAR(50) NOT NULL,
        RegularUnitPrice         DECIMAL(18,2) NOT NULL,
        SellingUnitPrice         DECIMAL(18,2) NOT NULL,
        CustomizationUnitPrice   DECIMAL(18,2) NOT NULL,
        Quantity                 INT NOT NULL,
        LineSubtotal             DECIMAL(18,2) NOT NULL,
        ProductDiscountAmount    DECIMAL(18,2) NOT NULL,
        LineTotal                DECIMAL(18,2) NOT NULL,
        SpecialInstructions      NVARCHAR(1000) NULL
    );
END;
GO

IF NOT EXISTS (SELECT * FROM sys.types WHERE is_table_type = 1 AND name = 'TT_ORDER_ITEM_CUSTOMIZATIONS')
BEGIN
    CREATE TYPE dbo.TT_ORDER_ITEM_CUSTOMIZATIONS AS TABLE
    (
        ItemTempId               INT NOT NULL,
        CustomizationOptionId    BIGINT NOT NULL,
        GroupNameEn              NVARCHAR(150) NOT NULL,
        GroupNameAr              NVARCHAR(150) NOT NULL,
        OptionNameEn             NVARCHAR(150) NOT NULL,
        OptionNameAr             NVARCHAR(150) NOT NULL,
        AdditionalPrice          DECIMAL(18,2) NOT NULL
    );
END;
GO
