-- Migration 0043: Cleanup - Drop legacy usp_Auth_ SPs, unwanted columns, and fix PR_AUTH_CREATE_OTP_VERIFICATION

-- =====================================================
-- 1. DROP ALL LEGACY usp_Auth_ STORED PROCEDURES
-- =====================================================
IF OBJECT_ID('dbo.usp_Auth_GetUserByUsername', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Auth_GetUserByUsername;
IF OBJECT_ID('dbo.usp_Auth_GetUserContext',    'P') IS NOT NULL DROP PROCEDURE dbo.usp_Auth_GetUserContext;
IF OBJECT_ID('dbo.usp_Auth_UpdateLastLogin',   'P') IS NOT NULL DROP PROCEDURE dbo.usp_Auth_UpdateLastLogin;
IF OBJECT_ID('dbo.usp_Auth_SaveRefreshToken',  'P') IS NOT NULL DROP PROCEDURE dbo.usp_Auth_SaveRefreshToken;
IF OBJECT_ID('dbo.usp_Auth_ValidateRefreshToken',          'P') IS NOT NULL DROP PROCEDURE dbo.usp_Auth_ValidateRefreshToken;
IF OBJECT_ID('dbo.usp_Auth_RevokeRefreshToken',            'P') IS NOT NULL DROP PROCEDURE dbo.usp_Auth_RevokeRefreshToken;
IF OBJECT_ID('dbo.usp_Auth_GetRolePermissions',            'P') IS NOT NULL DROP PROCEDURE dbo.usp_Auth_GetRolePermissions;
IF OBJECT_ID('dbo.usp_Auth_RevokeAllRefreshTokensByUserId','P') IS NOT NULL DROP PROCEDURE dbo.usp_Auth_RevokeAllRefreshTokensByUserId;
IF OBJECT_ID('dbo.usp_Auth_CreateUser',        'P') IS NOT NULL DROP PROCEDURE dbo.usp_Auth_CreateUser;
IF OBJECT_ID('dbo.usp_Logs_InsertActivityLog', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Logs_InsertActivityLog;
GO

-- =====================================================
-- 2. DROP UNUSED COLUMNS FROM USERS TABLE
-- =====================================================

-- Remove PASSWORD_HASH (not used in passwordless OTP auth)
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.USERS') AND name = 'PASSWORD_HASH')
    ALTER TABLE dbo.USERS DROP COLUMN PASSWORD_HASH;

-- Remove LOCKOUT_END_ON (replaced by OTP-level blocking logic)
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.USERS') AND name = 'LOCKOUT_END_ON')
    ALTER TABLE dbo.USERS DROP COLUMN LOCKOUT_END_ON;
GO

-- =====================================================
-- 3. FIX & FINALIZE PR_AUTH_CREATE_OTP_VERIFICATION
--    (ALL_CAPS variable names + fix @NewResendCount bug)
-- =====================================================
CREATE OR ALTER PROCEDURE dbo.PR_AUTH_CREATE_OTP_VERIFICATION
    @CountryCode        VARCHAR(10),
    @MobileNumber       VARCHAR(20),
    @OtpHash            VARCHAR(500),
    @OtpPurpose         VARCHAR(30),
    @ExpiresAt          DATETIME2,
    @MaxAttempts        INT              = 5,
    @WindowMinutes      INT              = 5,
    @MaxResendPerWindow INT              = 3,
    @ChallengeId        UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Step 1: Get the latest OTP record for this phone + purpose
    DECLARE @LAST_RESEND_COUNT     INT;
    DECLARE @LAST_WINDOW_START_AT  DATETIME2;

    SELECT TOP 1
        @LAST_RESEND_COUNT    = ISNULL(RESEND_COUNT, 0),
        @LAST_WINDOW_START_AT = RATE_LIMIT_WINDOW_START_AT
    FROM dbo.OTP_VERIFICATIONS
    WHERE COUNTRY_CODE = @CountryCode
      AND MOBILE_NUMBER = @MobileNumber
      AND OTP_PURPOSE   = @OtpPurpose
    ORDER BY OTP_ID DESC;

    -- Step 2: Determine window and resend count
    DECLARE @NEW_WINDOW_START_AT  DATETIME2;
    DECLARE @NEW_RESEND_COUNT     INT;

    IF @LAST_WINDOW_START_AT IS NOT NULL
       AND SYSUTCDATETIME() < DATEADD(MINUTE, @WindowMinutes, @LAST_WINDOW_START_AT)
    BEGIN
        -- Still inside the active window
        IF @LAST_RESEND_COUNT >= @MaxResendPerWindow
        BEGIN
            -- Window is full → block
            DECLARE @WINDOW_EXPIRES_AT  DATETIME2    = DATEADD(MINUTE, @WindowMinutes, @LAST_WINDOW_START_AT);
            DECLARE @WAIT_SECONDS       INT          = DATEDIFF(SECOND, SYSUTCDATETIME(), @WINDOW_EXPIRES_AT);
            DECLARE @WAIT_MINUTES       INT          = (@WAIT_SECONDS / 60) + 1;
            DECLARE @ERR_MSG            NVARCHAR(300) = FORMATMESSAGE(
                'OTP resend limit reached (%d/%d). Please try again in %d minute(s).',
                @LAST_RESEND_COUNT,
                @MaxResendPerWindow,
                @WAIT_MINUTES
            );
            RAISERROR(@ERR_MSG, 16, 1);
            RETURN;
        END

        -- Window still has capacity → continue in same window
        SET @NEW_WINDOW_START_AT = @LAST_WINDOW_START_AT;
        SET @NEW_RESEND_COUNT    = @LAST_RESEND_COUNT + 1;
    END
    ELSE
    BEGIN
        -- No window yet OR window expired → start a fresh window
        SET @NEW_WINDOW_START_AT = SYSUTCDATETIME();
        SET @NEW_RESEND_COUNT    = 1;
    END

    -- Step 3: Generate ChallengeId if not provided
    IF @ChallengeId IS NULL SET @ChallengeId = NEWID();

    -- Step 4: Invalidate any existing PENDING OTP for this phone + purpose
    UPDATE dbo.OTP_VERIFICATIONS
    SET OTP_STATUS = 'INVALIDATED',
        UPDATED_AT = SYSUTCDATETIME()
    WHERE COUNTRY_CODE = @CountryCode
      AND MOBILE_NUMBER = @MobileNumber
      AND OTP_PURPOSE   = @OtpPurpose
      AND OTP_STATUS    = 'PENDING';

    -- Step 5: Insert new OTP record
    INSERT INTO dbo.OTP_VERIFICATIONS
    (
        CHALLENGE_ID,
        COUNTRY_CODE,
        MOBILE_NUMBER,
        OTP_HASH,
        OTP_PURPOSE,
        ATTEMPT_COUNT,
        RESEND_COUNT,
        MAX_ATTEMPTS,
        OTP_STATUS,
        EXPIRES_AT,
        RATE_LIMIT_WINDOW_START_AT,
        CREATED_AT
    )
    VALUES
    (
        @ChallengeId,
        @CountryCode,
        @MobileNumber,
        @OtpHash,
        @OtpPurpose,
        0,
        @NEW_RESEND_COUNT,
        @MaxAttempts,
        'PENDING',
        @ExpiresAt,
        @NEW_WINDOW_START_AT,
        SYSUTCDATETIME()
    );

    DECLARE @NEW_OTP_ID BIGINT = SCOPE_IDENTITY();

    -- Step 6: Return OtpId, ChallengeId, and window info
    SELECT
        @NEW_OTP_ID             AS OtpId,
        @ChallengeId            AS ChallengeId,
        @NEW_RESEND_COUNT       AS ResendCount,
        @MaxResendPerWindow     AS MaxResendPerWindow,
        @NEW_WINDOW_START_AT    AS WindowStartAt,
        DATEADD(MINUTE, @WindowMinutes, @NEW_WINDOW_START_AT) AS WindowExpiresAt;
END;
GO
