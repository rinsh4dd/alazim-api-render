-- Migration 0044: Finalize PR_AUTH_CREATE_OTP_VERIFICATION (user style + INSERT column fix)

CREATE OR ALTER PROCEDURE [dbo].[PR_AUTH_CREATE_OTP_VERIFICATION]
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
	DECLARE @LAST_RESEND_COUNT INT, @LAST_WINDOW_START_AT DATETIME2;

	SELECT TOP 1
		@LAST_RESEND_COUNT    = ISNULL(RESEND_COUNT, 0),
		@LAST_WINDOW_START_AT = RATE_LIMIT_WINDOW_START_AT
	FROM dbo.OTP_VERIFICATIONS
	WHERE COUNTRY_CODE  = @CountryCode
	AND   MOBILE_NUMBER = @MobileNumber
	AND   OTP_PURPOSE   = @OtpPurpose
	ORDER BY OTP_ID DESC;

	DECLARE @NEW_WINDOW_START_AT DATETIME2, @NEW_RESEND_COUNT INT;

	IF @LAST_WINDOW_START_AT IS NOT NULL
	   AND SYSUTCDATETIME() < DATEADD(MINUTE, @WindowMinutes, @LAST_WINDOW_START_AT)
	BEGIN
		IF @LAST_RESEND_COUNT >= @MaxResendPerWindow
		BEGIN
			DECLARE @WINDOW_EXPIRES_AT DATETIME2     = DATEADD(MINUTE, @WindowMinutes, @LAST_WINDOW_START_AT);
			DECLARE @WAIT_SECONDS      INT           = DATEDIFF(SECOND, SYSUTCDATETIME(), @WINDOW_EXPIRES_AT);
			DECLARE @WAIT_MINUTES      INT           = (@WAIT_SECONDS / 60) + 1;
			DECLARE @ERR_MSG           NVARCHAR(300) = FORMATMESSAGE(
				'OTP resend limit reached (%d/%d). Please try again in %d minute(s).',
				@LAST_RESEND_COUNT, @MaxResendPerWindow, @WAIT_MINUTES
			);
			RAISERROR(@ERR_MSG, 16, 1);
			RETURN;
		END

		SET @NEW_WINDOW_START_AT = @LAST_WINDOW_START_AT;
		SET @NEW_RESEND_COUNT    = @LAST_RESEND_COUNT + 1;
	END
	ELSE
	BEGIN
		SET @NEW_WINDOW_START_AT = SYSUTCDATETIME();
		SET @NEW_RESEND_COUNT    = 1;
	END

	IF @ChallengeId IS NULL SET @ChallengeId = NEWID();

	UPDATE dbo.OTP_VERIFICATIONS
	SET OTP_STATUS = 'INVALIDATED', UPDATED_AT = SYSUTCDATETIME()
	WHERE COUNTRY_CODE  = @CountryCode
	AND   MOBILE_NUMBER = @MobileNumber
	AND   OTP_PURPOSE   = @OtpPurpose
	AND   OTP_STATUS    = 'PENDING';

	INSERT INTO dbo.OTP_VERIFICATIONS
	(CHALLENGE_ID, COUNTRY_CODE, MOBILE_NUMBER, OTP_HASH, OTP_PURPOSE,
	 ATTEMPT_COUNT, RESEND_COUNT, MAX_ATTEMPTS, OTP_STATUS, EXPIRES_AT,
	 RATE_LIMIT_WINDOW_START_AT, CREATED_AT)
	VALUES
	(@ChallengeId, @CountryCode, @MobileNumber, @OtpHash, @OtpPurpose,
	 0, @NEW_RESEND_COUNT, @MaxAttempts, 'PENDING', @ExpiresAt,
	 @NEW_WINDOW_START_AT, SYSUTCDATETIME());

	DECLARE @NEW_OTP_ID BIGINT = SCOPE_IDENTITY();

	SELECT
		@NEW_OTP_ID                                        AS OtpId,
		@ChallengeId                                       AS ChallengeId,
		@NEW_RESEND_COUNT                                  AS ResendCount,
		@MaxResendPerWindow                                AS MaxResendPerWindow,
		@NEW_WINDOW_START_AT                               AS WindowStartAt,
		DATEADD(MINUTE, @WindowMinutes, @NEW_WINDOW_START_AT) AS WindowExpiresAt;
END;
GO
