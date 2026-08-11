-- Migration 0041: Replace cooldown with 15-Minute Window (3 OTPs per 15 minutes per phone number)

CREATE OR ALTER PROCEDURE dbo.PR_AUTH_CREATE_OTP_VERIFICATION
    @CountryCode VARCHAR(10),
    @MobileNumber VARCHAR(20),
    @OtpHash VARCHAR(500),
    @OtpPurpose VARCHAR(30),
    @ExpiresAt DATETIME2,
    @MaxAttempts INT = 5,
    @WindowMinutes INT = 15,
    @MaxRequestsPerWindow INT = 3,
    @ChallengeId UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Count how many OTPs have been requested in the last 15 minutes for this phone+purpose
    DECLARE @OtpCountInWindow INT;
    DECLARE @OldestInWindowCreatedAt DATETIME2;

    SELECT 
        @OtpCountInWindow = COUNT(*),
        @OldestInWindowCreatedAt = MIN(CREATED_AT)
    FROM dbo.OTP_VERIFICATIONS
    WHERE COUNTRY_CODE = @CountryCode
      AND MOBILE_NUMBER = @MobileNumber
      AND OTP_PURPOSE = @OtpPurpose
      AND CREATED_AT >= DATEADD(MINUTE, -@WindowMinutes, SYSUTCDATETIME());

    -- 2. If 3 or more OTPs were created in the last 15 minutes, block the request
    IF @OtpCountInWindow >= @MaxRequestsPerWindow
    BEGIN
        DECLARE @RetryAfterSeconds INT = @WindowMinutes * 60 - DATEDIFF(SECOND, @OldestInWindowCreatedAt, SYSUTCDATETIME());
        DECLARE @RetryAfterMinutes INT = (@RetryAfterSeconds / 60) + 1;
        DECLARE @ErrMsg NVARCHAR(300) = FORMATMESSAGE(
            'OTP request limit reached. You have used %d of %d allowed requests in 15 minutes. Please try again in %d minute(s).',
            @OtpCountInWindow,
            @MaxRequestsPerWindow,
            @RetryAfterMinutes
        );
        RAISERROR(@ErrMsg, 16, 1);
        RETURN;
    END

    -- 3. Generate ChallengeId if not provided
    IF @ChallengeId IS NULL SET @ChallengeId = NEWID();

    -- 4. Invalidate existing pending OTPs for this number and purpose
    UPDATE dbo.OTP_VERIFICATIONS
    SET OTP_STATUS = 'INVALIDATED',
        UPDATED_AT = SYSUTCDATETIME()
    WHERE COUNTRY_CODE = @CountryCode
      AND MOBILE_NUMBER = @MobileNumber
      AND OTP_PURPOSE = @OtpPurpose
      AND OTP_STATUS = 'PENDING';

    -- 5. Insert new OTP record
    DECLARE @CurrentResendCount INT;
    SELECT @CurrentResendCount = ISNULL(MAX(RESEND_COUNT), 0) + 1
    FROM dbo.OTP_VERIFICATIONS
    WHERE COUNTRY_CODE = @CountryCode
      AND MOBILE_NUMBER = @MobileNumber
      AND OTP_PURPOSE = @OtpPurpose;

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
        @CurrentResendCount,
        @MaxAttempts,
        'PENDING',
        @ExpiresAt,
        SYSUTCDATETIME()
    );

    DECLARE @NewOtpId BIGINT = SCOPE_IDENTITY();

    SELECT @NewOtpId AS OtpId, @ChallengeId AS ChallengeId;
END;
GO
