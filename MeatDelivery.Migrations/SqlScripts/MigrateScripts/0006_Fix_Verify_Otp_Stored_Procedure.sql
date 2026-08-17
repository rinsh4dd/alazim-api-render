-- =============================================================================
-- Migration: 0006_Fix_Verify_Otp_Stored_Procedure.sql
-- Description:
-- Fixes PR_AUTH_VERIFY_OTP_AND_REGISTER_CUSTOMER parameter signature to match
-- C# UserRegistrationRepository.cs (12 arguments) and point to dbo.CUSTOMER_USERS.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_AUTH_VERIFY_OTP_AND_REGISTER_CUSTOMER
    @CountryCode VARCHAR(10),
    @MobileNumber VARCHAR(20),
    @OtpHash VARCHAR(500),
    @FullName NVARCHAR(150) = NULL,
    @LanguageCode VARCHAR(10) = 'EN',
    @RefreshTokenHash VARCHAR(500),
    @DeviceId VARCHAR(200) = NULL,
    @DeviceType VARCHAR(30) = NULL,
    @IpAddress VARCHAR(45) = NULL,
    @SessionExpiresAt DATETIME2,
    @MaxAttempts INT = 5,
    @ChallengeId UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OtpId BIGINT;
    DECLARE @StoredOtpHash VARCHAR(500);
    DECLARE @AttemptCount INT;
    DECLARE @OtpExpiresAt DATETIME2;
    DECLARE @OtpStatus VARCHAR(20);

    IF @ChallengeId IS NOT NULL
    BEGIN
        SELECT TOP 1 
            @OtpId = OTP_ID,
            @StoredOtpHash = OTP_HASH,
            @AttemptCount = ATTEMPT_COUNT,
            @OtpExpiresAt = EXPIRES_AT,
            @OtpStatus = OTP_STATUS
        FROM dbo.OTP_VERIFICATIONS
        WHERE CHALLENGE_ID = @ChallengeId;
    END
    ELSE
    BEGIN
        SELECT TOP 1 
            @OtpId = OTP_ID,
            @StoredOtpHash = OTP_HASH,
            @AttemptCount = ATTEMPT_COUNT,
            @OtpExpiresAt = EXPIRES_AT,
            @OtpStatus = OTP_STATUS
        FROM dbo.OTP_VERIFICATIONS
        WHERE COUNTRY_CODE = @CountryCode 
          AND MOBILE_NUMBER = @MobileNumber
          AND OTP_STATUS = 'PENDING'
        ORDER BY CREATED_AT DESC;
    END

    IF @OtpId IS NULL
    BEGIN
        RAISERROR('OTP verification record not found.', 16, 1);
        RETURN;
    END

    IF @OtpStatus <> 'PENDING'
    BEGIN
        RAISERROR('OTP is no longer valid or has already been used.', 16, 1);
        RETURN;
    END

    IF SYSUTCDATETIME() > @OtpExpiresAt
    BEGIN
        UPDATE dbo.OTP_VERIFICATIONS 
        SET OTP_STATUS = 'EXPIRED', UPDATED_AT = SYSUTCDATETIME()
        WHERE OTP_ID = @OtpId;

        RAISERROR('OTP code has expired. Please request a new OTP.', 16, 1);
        RETURN;
    END

    IF @AttemptCount >= @MaxAttempts
    BEGIN
        UPDATE dbo.OTP_VERIFICATIONS 
        SET OTP_STATUS = 'BLOCKED', UPDATED_AT = SYSUTCDATETIME()
        WHERE OTP_ID = @OtpId;

        RAISERROR('Maximum verification attempts exceeded. Please request a new OTP.', 16, 1);
        RETURN;
    END

    IF @StoredOtpHash <> @OtpHash
    BEGIN
        UPDATE dbo.OTP_VERIFICATIONS 
        SET ATTEMPT_COUNT = ATTEMPT_COUNT + 1, UPDATED_AT = SYSUTCDATETIME()
        WHERE OTP_ID = @OtpId;

        DECLARE @RemainingAttempts INT = @MaxAttempts - (@AttemptCount + 1);
        DECLARE @ErrorMessage NVARCHAR(200) = FORMATMESSAGE('Invalid OTP code. %d attempts remaining.', @RemainingAttempts);
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END

    SET XACT_ABORT ON;
    BEGIN TRANSACTION;

    UPDATE dbo.OTP_VERIFICATIONS 
    SET OTP_STATUS = 'VERIFIED', 
        VERIFIED_AT = SYSUTCDATETIME(),
        UPDATED_AT = SYSUTCDATETIME()
    WHERE OTP_ID = @OtpId;

    DECLARE @UserId BIGINT;
    DECLARE @IsNewUser BIT = 0;
    DECLARE @AllocatedDocNo VARCHAR(50) = NULL;

    SELECT @UserId = USER_ID 
    FROM dbo.CUSTOMER_USERS 
    WHERE COUNTRY_CODE = @CountryCode AND MOBILE_NUMBER = @MobileNumber;

    IF @UserId IS NULL
    BEGIN
        SET @IsNewUser = 1;

        -- Allocate Customer Document Number
        EXEC dbo.PR_GET_NEXT_DOC_NO
            @DOCTYPE = 'CUS1',
            @DOC_NO = @AllocatedDocNo OUTPUT;

        INSERT INTO dbo.CUSTOMER_USERS
        (
            COUNTRY_CODE,
            MOBILE_NUMBER,
            DOCTYPE,
            DOC_NO,
            FIRST_NAME,
            LAST_NAME,
            LANGUAGE_CODE,
            IS_MOBILE_VERIFIED,
            IS_EMAIL_VERIFIED,
            ELIGIBLE_FOR_ORDER,
            IS_PROFILE_COMPLETED,
            USER_STATUS,
            LAST_LOGIN_AT,
            CREATED_AT
        )
        VALUES
        (
            @CountryCode,
            @MobileNumber,
            'CUS1',
            @AllocatedDocNo,
            NULL,
            NULL,
            ISNULL(@LanguageCode, 'EN'),
            1,
            0,
            0,
            0,
            'ACTIVE',
            SYSUTCDATETIME(),
            SYSUTCDATETIME()
        );

        SET @UserId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.CUSTOMER_USERS
        SET IS_MOBILE_VERIFIED = 1,
            USER_STATUS = 'ACTIVE',
            LAST_LOGIN_AT = SYSUTCDATETIME(),
            UPDATED_AT = SYSUTCDATETIME()
        WHERE USER_ID = @UserId;
    END

    UPDATE dbo.OTP_VERIFICATIONS 
    SET USER_ID = @UserId 
    WHERE OTP_ID = @OtpId;

    DECLARE @SessionId BIGINT;

    INSERT INTO dbo.USER_SESSIONS
    (
        USER_ID,
        REFRESH_TOKEN_HASH,
        DEVICE_ID,
        DEVICE_TYPE,
        IP_ADDRESS,
        IS_ACTIVE,
        EXPIRES_AT,
        LAST_ACTIVITY_AT,
        CREATED_AT
    )
    VALUES
    (
        @UserId,
        @RefreshTokenHash,
        @DeviceId,
        @DeviceType,
        @IpAddress,
        1,
        @SessionExpiresAt,
        SYSUTCDATETIME(),
        SYSUTCDATETIME()
    );

    SET @SessionId = SCOPE_IDENTITY();

    COMMIT TRANSACTION;

    SELECT 
        u.USER_ID AS UserId,
        u.DOCTYPE AS DocType,
        u.DOC_NO AS DocNo,
        @SessionId AS SessionId,
        u.FIRST_NAME AS FirstName,
        u.LAST_NAME AS LastName,
        ISNULL(LTRIM(RTRIM(ISNULL(u.FIRST_NAME, '') + ' ' + ISNULL(u.LAST_NAME, ''))), '') AS FullName,
        u.LANGUAGE_CODE AS LanguageCode,
        u.ELIGIBLE_FOR_ORDER AS EligibleForOrder,
        u.IS_PROFILE_COMPLETED AS IsProfileCompleted,
        @IsNewUser AS IsNewUser,
        CAST(NULL AS VARCHAR(50)) AS RoleCode
    FROM dbo.CUSTOMER_USERS u
    WHERE u.USER_ID = @UserId;
END;
GO
