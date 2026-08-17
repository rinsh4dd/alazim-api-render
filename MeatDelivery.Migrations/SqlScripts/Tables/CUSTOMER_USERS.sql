-- =============================================================================
-- TABLE: dbo.CUSTOMER_USERS
-- Description: Stores customer accounts used by the mobile app and web clients.
-- Authentication: Mobile Number + OTP (Zero password, Zero customer roles)
-- =============================================================================

CREATE TABLE dbo.CUSTOMER_USERS
(
    USER_ID                 BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    DOCTYPE                 VARCHAR(10)          NULL,
    DOC_NO                  VARCHAR(30)          NULL,
    COUNTRY_CODE            VARCHAR(10)          NOT NULL,
    MOBILE_NUMBER           VARCHAR(20)          NOT NULL,
    EMAIL                   VARCHAR(150)         NULL,
    FIRST_NAME              NVARCHAR(100)        NULL,
    LAST_NAME               NVARCHAR(100)        NULL,
    DOB                     DATE                 NULL,
    GENDER                  VARCHAR(20)          NULL,
    PROFILE_IMAGE_URL       VARCHAR(500)         NULL,
    LANGUAGE_CODE           VARCHAR(10)          NOT NULL DEFAULT 'EN',
    IS_MOBILE_VERIFIED      BIT                  NOT NULL DEFAULT 0,
    IS_EMAIL_VERIFIED       BIT                  NOT NULL DEFAULT 0,
    ELIGIBLE_FOR_ORDER      BIT                  NOT NULL DEFAULT 0,
    IS_PROFILE_COMPLETED    BIT                  NOT NULL DEFAULT 0,
    USER_STATUS             VARCHAR(20)          NOT NULL DEFAULT 'PENDING',
    LAST_LOGIN_AT           DATETIME2            NULL,
    CREATED_AT              DATETIME2            NOT NULL DEFAULT SYSUTCDATETIME(),
    UPDATED_AT              DATETIME2            NULL,
    CONSTRAINT UQ_CUSTOMER_USERS_MOBILE UNIQUE (COUNTRY_CODE, MOBILE_NUMBER)
);

CREATE UNIQUE NONCLUSTERED INDEX UQ_CUSTOMER_USERS_EMAIL 
ON dbo.CUSTOMER_USERS(EMAIL) 
WHERE EMAIL IS NOT NULL;
GO
