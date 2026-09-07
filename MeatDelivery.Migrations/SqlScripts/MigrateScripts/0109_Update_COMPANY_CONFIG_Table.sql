-- =============================================================================
-- Migration: 0109_Update_COMPANY_CONFIG_Table.sql
-- Description: Creates or updates COMPANY_CONFIG master table schema with contact and location details.
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'COMPANY_CONFIG' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.COMPANY_CONFIG
    (
        COMPANY_CONFIG_ID           BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        COMPANY_CODE                VARCHAR(50)          NOT NULL CONSTRAINT UQ_COMPANY_CONFIG_CODE UNIQUE,
        COMPANY_NAME_EN             NVARCHAR(150)        NOT NULL,
        COMPANY_NAME_AR             NVARCHAR(150)        NULL,
        LEGAL_NAME                  NVARCHAR(200)        NULL,

        ADDRESS_LINE_1              NVARCHAR(250)        NULL,
        ADDRESS_LINE_2              NVARCHAR(250)        NULL,
        LANDMARK                    NVARCHAR(150)        NULL,
        CITY                        NVARCHAR(100)        NULL,
        STATE                       NVARCHAR(100)        NULL,
        COUNTRY_CODE                VARCHAR(10)          NULL,
        POSTAL_CODE                 VARCHAR(20)          NULL,

        LATITUDE                    DECIMAL(10,8)        NULL,
        LONGITUDE                   DECIMAL(11,8)        NULL,
        GOOGLE_PLACE_ID             VARCHAR(255)         NULL,

        CONTACT_COUNTRY_CODE        VARCHAR(10)          NULL,
        CONTACT_NUMBER              VARCHAR(30)          NULL,
        WHATSAPP_NUMBER             VARCHAR(30)          NULL,
        EMAIL                       VARCHAR(150)         NULL,
        WEBSITE_URL                 VARCHAR(255)         NULL,
        LOGO_URL                    VARCHAR(500)         NULL,

        IS_ACTIVE                   BIT                  NOT NULL DEFAULT 1,
        CREATED_BY_ADMIN_USER_ID    BIGINT               NULL CONSTRAINT FK_COMPANY_CONFIG_CREATED_BY REFERENCES dbo.ADMIN_USERS(ADMIN_USER_ID),
        CREATED_AT                  DATETIME2            NOT NULL DEFAULT SYSUTCDATETIME(),
        UPDATED_AT                  DATETIME2            NULL
    );
END
ELSE
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') AND name = 'COMPANY_NAME_EN')
    BEGIN
        ALTER TABLE dbo.COMPANY_CONFIG ADD COMPANY_NAME_EN NVARCHAR(150) NULL;
        EXEC sp_executesql N'UPDATE dbo.COMPANY_CONFIG SET COMPANY_NAME_EN = COMPANY_NAME WHERE COMPANY_NAME_EN IS NULL AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''dbo.COMPANY_CONFIG'') AND name = ''COMPANY_NAME'');';
    END

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') AND name = 'COMPANY_NAME_AR')
        ALTER TABLE dbo.COMPANY_CONFIG ADD COMPANY_NAME_AR NVARCHAR(150) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') AND name = 'LEGAL_NAME')
        ALTER TABLE dbo.COMPANY_CONFIG ADD LEGAL_NAME NVARCHAR(200) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') AND name = 'ADDRESS_LINE_1')
        ALTER TABLE dbo.COMPANY_CONFIG ADD ADDRESS_LINE_1 NVARCHAR(250) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') AND name = 'ADDRESS_LINE_2')
        ALTER TABLE dbo.COMPANY_CONFIG ADD ADDRESS_LINE_2 NVARCHAR(250) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') AND name = 'LANDMARK')
        ALTER TABLE dbo.COMPANY_CONFIG ADD LANDMARK NVARCHAR(150) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') AND name = 'CITY')
        ALTER TABLE dbo.COMPANY_CONFIG ADD CITY NVARCHAR(100) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') AND name = 'STATE')
        ALTER TABLE dbo.COMPANY_CONFIG ADD STATE NVARCHAR(100) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') AND name = 'COUNTRY_CODE')
        ALTER TABLE dbo.COMPANY_CONFIG ADD COUNTRY_CODE VARCHAR(10) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') AND name = 'POSTAL_CODE')
        ALTER TABLE dbo.COMPANY_CONFIG ADD POSTAL_CODE VARCHAR(20) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') AND name = 'LATITUDE')
        ALTER TABLE dbo.COMPANY_CONFIG ADD LATITUDE DECIMAL(10,8) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') AND name = 'LONGITUDE')
        ALTER TABLE dbo.COMPANY_CONFIG ADD LONGITUDE DECIMAL(11,8) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') AND name = 'GOOGLE_PLACE_ID')
        ALTER TABLE dbo.COMPANY_CONFIG ADD GOOGLE_PLACE_ID VARCHAR(255) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') AND name = 'CONTACT_COUNTRY_CODE')
        ALTER TABLE dbo.COMPANY_CONFIG ADD CONTACT_COUNTRY_CODE VARCHAR(10) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') AND name = 'CONTACT_NUMBER')
        ALTER TABLE dbo.COMPANY_CONFIG ADD CONTACT_NUMBER VARCHAR(30) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') AND name = 'WHATSAPP_NUMBER')
        ALTER TABLE dbo.COMPANY_CONFIG ADD WHATSAPP_NUMBER VARCHAR(30) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') AND name = 'EMAIL')
        ALTER TABLE dbo.COMPANY_CONFIG ADD EMAIL VARCHAR(150) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') AND name = 'WEBSITE_URL')
        ALTER TABLE dbo.COMPANY_CONFIG ADD WEBSITE_URL VARCHAR(255) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') AND name = 'LOGO_URL')
        ALTER TABLE dbo.COMPANY_CONFIG ADD LOGO_URL VARCHAR(500) NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.COMPANY_CONFIG') AND name = 'CREATED_BY_ADMIN_USER_ID')
        ALTER TABLE dbo.COMPANY_CONFIG ADD CREATED_BY_ADMIN_USER_ID BIGINT NULL CONSTRAINT FK_COMPANY_CONFIG_CREATED_BY REFERENCES dbo.ADMIN_USERS(ADMIN_USER_ID);
END
GO

-- Seed default company record if not present
IF NOT EXISTS (SELECT 1 FROM dbo.COMPANY_CONFIG WHERE COMPANY_CODE = 'AL_AZEEM')
BEGIN
    INSERT INTO dbo.COMPANY_CONFIG
    (
        COMPANY_CODE,
        COMPANY_NAME_EN,
        COMPANY_NAME_AR,
        LEGAL_NAME,
        ADDRESS_LINE_1,
        CITY,
        COUNTRY_CODE,
        CONTACT_COUNTRY_CODE,
        CONTACT_NUMBER,
        EMAIL,
        IS_ACTIVE,
        CREATED_AT
    )
    VALUES
    (
        'AL_AZEEM',
        N'Al Azeem Meat Store',
        N'العزيمة لتجارة اللحوم',
        N'Al Azeem Meat Delivery Trading LLC',
        N'Main Street',
        N'Dubai',
        'UAE',
        '+971',
        '500000000',
        'info@alazeemmeat.com',
        1,
        SYSUTCDATETIME()
    );
END
GO

