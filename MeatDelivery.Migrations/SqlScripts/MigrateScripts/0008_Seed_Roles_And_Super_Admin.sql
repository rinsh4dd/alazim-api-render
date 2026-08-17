-- =============================================================================
-- Migration: 0008_Seed_Roles_And_Super_Admin.sql
-- Description:
-- 1. Seeds the 5 standard Admin Roles into dbo.ROLES
-- 2. Ensures dbo.ADMIN_USER_ROLES mapping table exists
-- 3. Seeds the bootstrap SUPER_ADMIN into dbo.ADMIN_USERS
-- 4. Assigns the SUPER_ADMIN role to the seeded super admin user
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. SEED 5 ADMIN ROLES INTO dbo.ROLES
-- -----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.ROLES WHERE ROLE_CODE = 'SUPER_ADMIN')
BEGIN
    INSERT INTO dbo.ROLES (ROLE_CODE, ROLE_NAME, DESCRIPTION, IS_ACTIVE)
    VALUES ('SUPER_ADMIN', 'Super Administrator', 'Full system access and super user permissions across all stores and configurations', 1);
END;

IF NOT EXISTS (SELECT 1 FROM dbo.ROLES WHERE ROLE_CODE = 'ADMINISTRATOR')
BEGIN
    INSERT INTO dbo.ROLES (ROLE_CODE, ROLE_NAME, DESCRIPTION, IS_ACTIVE)
    VALUES ('ADMINISTRATOR', 'Administrator', 'Operational administration across catalog, orders, delivery, and promotions', 1);
END;

IF NOT EXISTS (SELECT 1 FROM dbo.ROLES WHERE ROLE_CODE = 'INVENTORY_MANAGER')
BEGIN
    INSERT INTO dbo.ROLES (ROLE_CODE, ROLE_NAME, DESCRIPTION, IS_ACTIVE)
    VALUES ('INVENTORY_MANAGER', 'Inventory Manager', 'Manages products, categories, cuts, weight options, pricing, and stock levels', 1);
END;

IF NOT EXISTS (SELECT 1 FROM dbo.ROLES WHERE ROLE_CODE = 'ORDER_MANAGER')
BEGIN
    INSERT INTO dbo.ROLES (ROLE_CODE, ROLE_NAME, DESCRIPTION, IS_ACTIVE)
    VALUES ('ORDER_MANAGER', 'Order Manager', 'Manages order processing, dispatch, delivery slots, and driver assignments', 1);
END;

IF NOT EXISTS (SELECT 1 FROM dbo.ROLES WHERE ROLE_CODE = 'CUSTOMER_SUPPORT')
BEGIN
    INSERT INTO dbo.ROLES (ROLE_CODE, ROLE_NAME, DESCRIPTION, IS_ACTIVE)
    VALUES ('CUSTOMER_SUPPORT', 'Customer Support', 'Manages customer support inquiries, complaints, and product reviews', 1);
END;
GO

-- -----------------------------------------------------------------------------
-- 2. ENSURE dbo.ADMIN_USER_ROLES TABLE EXISTS
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.ADMIN_USER_ROLES', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ADMIN_USER_ROLES
    (
        ADMIN_USER_ROLE_ID        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        ADMIN_USER_ID             BIGINT               NOT NULL,
        ROLE_ID                   INT                  NOT NULL,
        IS_ACTIVE                 BIT                  NOT NULL DEFAULT 1,
        ASSIGNED_AT               DATETIME2            NOT NULL DEFAULT SYSUTCDATETIME(),
        ASSIGNED_BY_ADMIN_USER_ID BIGINT               NULL,
        UPDATED_AT                DATETIME2            NULL,
        CONSTRAINT FK_ADMIN_USER_ROLES_ADMIN FOREIGN KEY (ADMIN_USER_ID) REFERENCES dbo.ADMIN_USERS(ADMIN_USER_ID),
        CONSTRAINT FK_ADMIN_USER_ROLES_ROLE FOREIGN KEY (ROLE_ID) REFERENCES dbo.ROLES(ROLE_ID),
        CONSTRAINT FK_ADMIN_USER_ROLES_ASSIGNED_BY FOREIGN KEY (ASSIGNED_BY_ADMIN_USER_ID) REFERENCES dbo.ADMIN_USERS(ADMIN_USER_ID),
        CONSTRAINT UQ_ADMIN_USER_ROLES UNIQUE (ADMIN_USER_ID, ROLE_ID)
    );
END;
GO

-- -----------------------------------------------------------------------------
-- 3. SEED DEFAULT SUPER_ADMIN USER IN dbo.ADMIN_USERS
-- Default Email: admin@alazima.com
-- Default Password: SuperAdmin@2026! (BCrypt WorkFactor 12)
-- -----------------------------------------------------------------------------
DECLARE @SuperAdminEmail VARCHAR(150) = 'admin@alazima.com';
DECLARE @SuperAdminHash VARCHAR(500) = '$2a$12$fFxI9Yb.uQx9SvY48Bx1nOXHmzHYmNz8ylVxdH.Gxpw4KJfd2IqU.';
DECLARE @AdminUserId BIGINT;
DECLARE @SuperAdminRoleId INT;

-- Find or insert Super Admin user
SELECT @AdminUserId = ADMIN_USER_ID 
FROM dbo.ADMIN_USERS 
WHERE EMAIL = @SuperAdminEmail;

IF @AdminUserId IS NULL
BEGIN
    INSERT INTO dbo.ADMIN_USERS
    (
        EMAIL,
        PASSWORD_HASH,
        FIRST_NAME,
        LAST_NAME,
        COUNTRY_CODE,
        MOBILE_NUMBER,
        ADMIN_STATUS,
        FAILED_LOGIN_COUNT,
        PASSWORD_CHANGED_AT,
        CREATED_AT
    )
    VALUES
    (
        @SuperAdminEmail,
        @SuperAdminHash,
        'Super',
        'Admin',
        '+971',
        '500000001',
        'ACTIVE',
        0,
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    );

    SET @AdminUserId = SCOPE_IDENTITY();
END;

-- -----------------------------------------------------------------------------
-- 4. ASSIGN SUPER_ADMIN ROLE TO THE SEEDED SUPER ADMIN USER
-- -----------------------------------------------------------------------------
SELECT @SuperAdminRoleId = ROLE_ID 
FROM dbo.ROLES 
WHERE ROLE_CODE = 'SUPER_ADMIN';

IF @AdminUserId IS NOT NULL AND @SuperAdminRoleId IS NOT NULL
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM dbo.ADMIN_USER_ROLES 
        WHERE ADMIN_USER_ID = @AdminUserId 
          AND ROLE_ID = @SuperAdminRoleId
    )
    BEGIN
        INSERT INTO dbo.ADMIN_USER_ROLES
        (
            ADMIN_USER_ID,
            ROLE_ID,
            IS_ACTIVE,
            ASSIGNED_AT
        )
        VALUES
        (
            @AdminUserId,
            @SuperAdminRoleId,
            1,
            SYSUTCDATETIME()
        );
    END;
END;
GO
