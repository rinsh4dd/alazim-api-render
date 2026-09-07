-- =============================================================================
-- Migration: 0112_Seed_Default_Company_Config.sql
-- Description: Seeds the initial default company configuration record into dbo.COMPANY_CONFIG if not present.
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM dbo.COMPANY_CONFIG WHERE COMPANY_CODE = 'AL_AZEEM' OR COMPANY_CONFIG_ID = 1)
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
