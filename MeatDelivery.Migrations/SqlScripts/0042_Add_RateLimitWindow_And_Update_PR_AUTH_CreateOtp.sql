-- Migration 0042: Add RATE_LIMIT_WINDOW_START_AT column & update PR_AUTH_CREATE_OTP_VERIFICATION
-- Replaces old 60-second cooldown with column-based 5-minute window (max 3 resends per window)

-- 1. Add new column to OTP_VERIFICATIONS
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.OTP_VERIFICATIONS') AND name = 'RATE_LIMIT_WINDOW_START_AT')
BEGIN
    ALTER TABLE dbo.OTP_VERIFICATIONS
    ADD RATE_LIMIT_WINDOW_START_AT DATETIME2 NULL;
END
GO

-- 2. Update PR_AUTH_CREATE_OTP_VERIFICATION with column-based window rate limiting
CREATE OR ALTER PROCEDURE dbo.PR_AUTH_CREATE_OTP_VERIFICATION
    @CountryCode       VARCHAR(10),
    @MobileNumber      VARCHAR(20),
    @OtpHash           VARCHAR(500),
    @OtpPurpose        VARCHAR(30),
    @ExpiresAt         DATETIME2,
    @MaxAttempts       INT             = 5,
    @WindowMinutes     INT             = 5,
    @MaxResendPerWindow INT            = 3,
    @ChallengeId       UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Step 1: Get the latest OTP record for this phone + purpose
    DECLARE @LAST_RESENT_COUNT          INT;
    DECLARE @LAST_WINDOW_START_AT        DATETIME2;

    SELECT TOP 1
        @LAST_RESENT_COUNT   = ISNULL(RESEND_COUNT, 0),
       @LAST_WINDOW_START_AT = RATE_LIMIT_WINDOW_START_AT
    FROM dbo.OTP_VERIFICATIONS
    WHERE COUNTRY_CODE = @CountryCode
      AND MOBILE_NUMBER = @MobileNumber
      AND OTP_PURPOSE   = @OtpPurpose
    ORDER BY OTP_ID DESC;

    -- Step 2: Determine new window values
    DECLARE @NEW_WINDOW_START_AT  DATETIME2;
    DECLARE @NEW_RESEND_COUNT   INT;

    IF@LAST_WINDOW_START_AT IS NOT NULL
       AND SYSUTCDATETIME() < DATEADD(MINUTE, @WindowMinutes,@LAST_WINDOW_START_AT)
    BEGIN
        -- Still inside the active window
        IF @LAST_RESENT_COUNT >= @MaxResendPerWindow
        BEGIN
            -- Window is full → block and tell user how long to wait
            DECLARE @WindowExpiresAt  DATETIME2 = DATEADD(MINUTE, @WindowMinutes,@LAST_WINDOW_START_AT);
            DECLARE @WaitSeconds      INT        = DATEDIFF(SECOND, SYSUTCDATETIME(), @WindowExpiresAt);
            DECLARE @WaitMinutes      INT        = (@WaitSeconds / 60) + 1;
            DECLARE @ErrMsg           NVARCHAR(300) = FORMATMESSAGE(
                'OTP resend limit reached (%d/%d). Please try again in %d minute(s).',
                @LAST_RESENT_COUNT,
                @MaxResendPerWindow,
                @WaitMinutes
            );
            RAISERROR(@ErrMsg, 16, 1);
            RETURN;
        END

        SET @NEW_WINDOW_START_AT =@LAST_WINDOW_START_AT;
        SET @NEW_RESEND_COUNT  = @LAST_RESENT_COUNT + 1;
    END
    ELSE
    BEGIN
        -- No window yet OR window expired → start a fresh window
        SET @NEW_WINDOW_START_AT = SYSUTCDATETIME();
        SET @NEW_RESEND_COUNT  = 1;
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

    -- Step 5: Insert the new OTP record with window tracking columns
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
        @NewResendCount,
        @MaxAttempts,
        'PENDING',
        @ExpiresAt,
        @NEW_WINDOW_START_AT,
        SYSUTCDATETIME()
    );

    DECLARE @NewOtpId BIGINT = SCOPE_IDENTITY();

    SELECT
        @NewOtpId        AS OtpId,
        @ChallengeId     AS ChallengeId,
        @NEW_RESEND_COUNT AS ResendCount,
        @MaxResendPerWindow AS MaxResendPerWindow,
        @NEW_WINDOW_START_AT AS WindowStartAt,
        DATEADD(MINUTE, @WindowMinutes, @NEW_WINDOW_START_AT) AS WindowExpiresAt;
END;
GO
