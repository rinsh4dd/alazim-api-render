-- Migration 0038: Update PR_AUTH_CREATE_OTP_VERIFICATION with 60s cooldown and resend limits

CREATE OR ALTER PROCEDURE dbo.PR_AUTH_CREATE_OTP_VERIFICATION
    @CountryCode VARCHAR(10),
    @MobileNumber VARCHAR(20),
    @OtpHash VARCHAR(500),
    @OtpPurpose VARCHAR(30),
    @ExpiresAt DATETIME2,
    @MaxAttempts INT = 5,
    @MinResendIntervalSeconds INT = 60,
    @MaxResendLimit INT = 5
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LastCreatedAt DATETIME2;
    DECLARE @LastResendCount INT = 0;

    -- Check last OTP record for this mobile & purpose
    SELECT TOP 1 
        @LastCreatedAt = CREATED_AT,
        @LastResendCount = ISNULL(RESEND_COUNT, 0)
    FROM dbo.OTP_VERIFICATIONS
    WHERE COUNTRY_CODE = @CountryCode 
      AND MOBILE_NUMBER = @MobileNumber 
      AND OTP_PURPOSE = @OtpPurpose
    ORDER BY OTP_ID DESC;

    -- 1. Cooldown Protection: Check if created within last N seconds (e.g. 60 seconds)
    IF @LastCreatedAt IS NOT NULL AND DATEDIFF(SECOND, @LastCreatedAt, SYSUTCDATETIME()) < @MinResendIntervalSeconds
    BEGIN
        DECLARE @WaitSeconds INT = @MinResendIntervalSeconds - DATEDIFF(SECOND, @LastCreatedAt, SYSUTCDATETIME());
        DECLARE @ErrMsg NVARCHAR(250) = FORMATMESSAGE('Please wait %d seconds before requesting another OTP.', @WaitSeconds);
        RAISERROR(@ErrMsg, 16, 1);
        RETURN;
    END

    -- 2. Max Resend Limit: Check if resend count exceeded
    IF @LastResendCount >= @MaxResendLimit
    BEGIN
        IF DATEDIFF(MINUTE, @LastCreatedAt, SYSUTCDATETIME()) < 30
        BEGIN
            RAISERROR('Maximum OTP resend limit exceeded. Please try again after 30 minutes.', 16, 1);
            RETURN;
        END
        ELSE
        BEGIN
            SET @LastResendCount = 0;
        END
    END

    DECLARE @CurrentResendCount INT = @LastResendCount + 1;

    -- Invalidate existing pending OTPs for this number and purpose
    UPDATE dbo.OTP_VERIFICATIONS
    SET OTP_STATUS = 'INVALIDATED',
        UPDATED_AT = SYSUTCDATETIME()
    WHERE COUNTRY_CODE = @CountryCode 
      AND MOBILE_NUMBER = @MobileNumber 
      AND OTP_PURPOSE = @OtpPurpose 
      AND OTP_STATUS = 'PENDING';

    -- Insert new OTP record
    INSERT INTO dbo.OTP_VERIFICATIONS
    (
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

    SELECT SCOPE_IDENTITY() AS OtpId;
END;
GO
