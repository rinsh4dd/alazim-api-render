-- =============================================================================
-- TABLE: dbo.COMPANY_CONFIG
-- Description: Company configuration master table containing contact, location, delivery timing, and system administrative details.
-- =============================================================================

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

    ADVANCE_DELIVERY_DAYS       INT                  NOT NULL DEFAULT 30,
    DELIVERY_START_TIME         TIME                 NOT NULL DEFAULT '08:00:00',
    DELIVERY_END_TIME           TIME                 NOT NULL DEFAULT '22:00:00',

    IS_ACTIVE                   BIT                  NOT NULL DEFAULT 1,
    CREATED_BY_ADMIN_USER_ID    BIGINT               NULL CONSTRAINT FK_COMPANY_CONFIG_CREATED_BY REFERENCES dbo.ADMIN_USERS(ADMIN_USER_ID),
    CREATED_AT                  DATETIME2            NOT NULL DEFAULT SYSUTCDATETIME(),
    UPDATED_AT                  DATETIME2            NULL
);
GO
