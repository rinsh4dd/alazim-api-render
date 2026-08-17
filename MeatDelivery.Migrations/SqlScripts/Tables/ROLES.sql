-- =============================================================================
-- TABLE: dbo.ROLES
-- Description: Stores admin authorization roles only (Customers have no roles).
-- Roles: SUPER_ADMIN, ADMINISTRATOR, INVENTORY_MANAGER, ORDER_MANAGER, CUSTOMER_SUPPORT
-- =============================================================================

CREATE TABLE dbo.ROLES
(
    ROLE_ID     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ROLE_CODE   VARCHAR(50)       NOT NULL UNIQUE,
    ROLE_NAME   VARCHAR(100)      NOT NULL,
    DESCRIPTION VARCHAR(500)      NULL,
    IS_ACTIVE   BIT               NOT NULL DEFAULT 1,
    CREATED_AT  DATETIME2         NOT NULL DEFAULT SYSUTCDATETIME(),
    UPDATED_AT  DATETIME2         NULL
);
GO
