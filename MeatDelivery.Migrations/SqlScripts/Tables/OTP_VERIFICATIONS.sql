-- =============================================================================
-- TABLE: dbo.OTP_VERIFICATIONS
-- Description: Customer mobile OTP verification and rate limiting.
-- =============================================================================

CREATE TABLE dbo.OTP_VERIFICATIONS
(
    OTP_ID                     BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CHALLENGE_ID               UNIQUEIDENTIFIER     NOT NULL DEFAULT NEWID(),
    USER_ID                    BIGINT               NULL,
    COUNTRY_CODE               VARCHAR(10)          NOT NULL,
    MOBILE_NUMBER              VARCHAR(20)          NOT NULL,
    OTP_HASH                   VARCHAR(500)         NOT NULL,
    OTP_PURPOSE                VARCHAR(30)          NOT NULL,
    ATTEMPT_COUNT              INT                  NOT NULL DEFAULT 0,
    RESEND_COUNT               INT                  NOT NULL DEFAULT 0,
    MAX_ATTEMPTS               INT                  NOT NULL DEFAULT 5,
    OTP_STATUS                 VARCHAR(20)          NOT NULL DEFAULT 'PENDING',
    EXPIRES_AT                 DATETIME2            NOT NULL,
    RATE_LIMIT_WINDOW_START_AT DATETIME2            NOT NULL DEFAULT SYSUTCDATETIME(),
    VERIFIED_AT                DATETIME2            NULL,
    CREATED_AT                 DATETIME2            NOT NULL DEFAULT SYSUTCDATETIME(),
    UPDATED_AT                 DATETIME2            NULL,
    CONSTRAINT FK_OTP_VERIFICATIONS_USER FOREIGN KEY (USER_ID) REFERENCES dbo.CUSTOMER_USERS(USER_ID)
);

CREATE UNIQUE NONCLUSTERED INDEX UQ_OTP_VERIFICATIONS_CHALLENGE_ID 
ON dbo.OTP_VERIFICATIONS(CHALLENGE_ID);

CREATE NONCLUSTERED INDEX IX_OTP_VERIFICATIONS_LOOKUP 
ON dbo.OTP_VERIFICATIONS(COUNTRY_CODE, MOBILE_NUMBER, OTP_STATUS);
GO
