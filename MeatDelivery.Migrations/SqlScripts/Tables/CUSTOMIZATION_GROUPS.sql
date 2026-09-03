-- =============================================================================
-- TABLE: dbo.CUSTOMIZATION_GROUPS
-- Description: Reusable customization groups/questions (e.g., Cleaning, Skin, Cut Type, Packing, Marination)
-- =============================================================================

CREATE TABLE dbo.CUSTOMIZATION_GROUPS
(
    CUSTOMIZATION_GROUP_ID          BIGINT IDENTITY(1,1) NOT NULL,
    GROUP_CODE                      VARCHAR(50) NOT NULL,
    GROUP_NAME_EN                   NVARCHAR(150) NOT NULL,
    GROUP_NAME_AR                   NVARCHAR(150) NOT NULL,
    IS_ADDITIONAL_PRICE_AVAILABLE   BIT NOT NULL DEFAULT 0,
    PRICING_TYPE                    VARCHAR(30) NULL DEFAULT ('ADDITIONAL_PRICE'),
    IS_CUSTOM_DATA_ALLOWED          BIT NOT NULL DEFAULT (0),
    IS_ACTIVE                       BIT NOT NULL DEFAULT 1,
    CREATED_AT                      DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UPDATED_AT                      DATETIME2 NULL,

    CONSTRAINT PK_CUSTOMIZATION_GROUPS PRIMARY KEY CLUSTERED (CUSTOMIZATION_GROUP_ID),
    CONSTRAINT UQ_CUSTOMIZATION_GROUPS_CODE UNIQUE NONCLUSTERED (GROUP_CODE)
);

CREATE NONCLUSTERED INDEX IX_CUSTOMIZATION_GROUPS_ACTIVE 
    ON dbo.CUSTOMIZATION_GROUPS (IS_ACTIVE);
GO
