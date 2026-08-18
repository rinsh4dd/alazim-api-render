-- =============================================================================
-- Migration: 0018_Create_Categories_Table
-- Date: 2026-08-18
-- Description: Creates dbo.CATEGORIES table (required by PR_SAVE_CATEGORY).
--              Supports hierarchical categories with parent-child relationships.
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'CATEGORIES')
BEGIN
    CREATE TABLE dbo.CATEGORIES
    (
        CATEGORY_ID         BIGINT IDENTITY(1,1) NOT NULL,
        PARENT_CATEGORY_ID  BIGINT NULL,
        CATEGORY_CODE       VARCHAR(50) NULL,
        CATEGORY_NAME_EN    VARCHAR(150) NOT NULL,
        CATEGORY_NAME_AR    NVARCHAR(150) NULL,
        DESCRIPTION_EN      VARCHAR(500) NULL,
        DESCRIPTION_AR      NVARCHAR(500) NULL,
        IMAGE_URL           VARCHAR(500) NULL,
        DISPLAY_ORDER       INT NOT NULL DEFAULT 0,
        IS_ACTIVE           BIT NOT NULL DEFAULT 1,
        IS_VISIBLE          BIT NOT NULL DEFAULT 1,
        CREATED_AT          DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UPDATED_AT          DATETIME2 NULL,

        CONSTRAINT PK_CATEGORIES PRIMARY KEY CLUSTERED (CATEGORY_ID),
        CONSTRAINT FK_CATEGORIES_PARENT FOREIGN KEY (PARENT_CATEGORY_ID) 
            REFERENCES dbo.CATEGORIES (CATEGORY_ID)
    );

    -- Index for parent lookups (subcategory queries)
    CREATE NONCLUSTERED INDEX IX_CATEGORIES_PARENT 
        ON dbo.CATEGORIES (PARENT_CATEGORY_ID) 
        WHERE PARENT_CATEGORY_ID IS NOT NULL;

    -- Index for unique category code
    CREATE UNIQUE NONCLUSTERED INDEX IX_CATEGORIES_CODE 
        ON dbo.CATEGORIES (CATEGORY_CODE) 
        WHERE CATEGORY_CODE IS NOT NULL;

    -- Index for display ordering
    CREATE NONCLUSTERED INDEX IX_CATEGORIES_DISPLAY_ORDER 
        ON dbo.CATEGORIES (DISPLAY_ORDER, IS_ACTIVE, IS_VISIBLE);
END;
GO
