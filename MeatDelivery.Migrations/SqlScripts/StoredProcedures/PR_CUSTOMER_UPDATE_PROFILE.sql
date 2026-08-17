-- =============================================================================
-- STORED PROCEDURE: dbo.PR_CUSTOMER_UPDATE_PROFILE
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_CUSTOMER_UPDATE_PROFILE
    @USER_ID            BIGINT,
    @FIRST_NAME         NVARCHAR(100) = NULL,
    @LAST_NAME          NVARCHAR(100) = NULL,
    @EMAIL              VARCHAR(150)  = NULL,
    @DOB                DATE          = NULL,
    @GENDER             VARCHAR(20)   = NULL,
    @PROFILE_IMAGE_URL  VARCHAR(500)  = NULL,
    @LANGUAGE_CODE      VARCHAR(10)   = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.CUSTOMER_USERS WHERE USER_ID = @USER_ID)
    BEGIN
        RAISERROR('Customer user not found.', 16, 1);
        RETURN;
    END

    -- Clean trimmed inputs
    DECLARE @CleanFirstName NVARCHAR(100) = NULLIF(LTRIM(RTRIM(@FIRST_NAME)), '');
    DECLARE @CleanLastName NVARCHAR(100) = NULLIF(LTRIM(RTRIM(@LAST_NAME)), '');
    DECLARE @CleanEmail VARCHAR(150) = NULLIF(LTRIM(RTRIM(@EMAIL)), '');
    DECLARE @CleanGender VARCHAR(20) = NULLIF(LTRIM(RTRIM(@GENDER)), '');
    DECLARE @CleanProfileImageUrl VARCHAR(500) = NULLIF(LTRIM(RTRIM(@PROFILE_IMAGE_URL)), '');
    DECLARE @CleanLanguageCode VARCHAR(10) = NULLIF(LTRIM(RTRIM(@LANGUAGE_CODE)), '');

    -- Check unique email if provided
    IF @CleanEmail IS NOT NULL
    BEGIN
        IF EXISTS (
            SELECT 1 
            FROM dbo.CUSTOMER_USERS 
            WHERE EMAIL = @CleanEmail 
              AND USER_ID <> @USER_ID
        )
        BEGIN
            RAISERROR('Email address is already registered to another account.', 16, 1);
            RETURN;
        END
    END

    DECLARE @CurrentUtc DATETIME2 = SYSUTCDATETIME();

    -- Determine Effective Values
    DECLARE @EffectiveFirstName NVARCHAR(100);
    DECLARE @EffectiveLastName NVARCHAR(100);
    DECLARE @EffectiveEmail VARCHAR(150);
    DECLARE @EffectiveDob DATE;
    DECLARE @EffectiveGender VARCHAR(20);

    SELECT 
        @EffectiveFirstName = ISNULL(@CleanFirstName, FIRST_NAME),
        @EffectiveLastName = ISNULL(@CleanLastName, LAST_NAME),
        @EffectiveEmail = ISNULL(@CleanEmail, EMAIL),
        @EffectiveDob = ISNULL(@DOB, DOB),
        @EffectiveGender = ISNULL(@CleanGender, GENDER)
    FROM dbo.CUSTOMER_USERS
    WHERE USER_ID = @USER_ID;

    -- Calculate ELIGIBLE_FOR_ORDER & IS_PROFILE_COMPLETED
    DECLARE @EligibleForOrder BIT = 0;
    IF @EffectiveFirstName IS NOT NULL AND @EffectiveLastName IS NOT NULL
    BEGIN
        SET @EligibleForOrder = 1;
    END

    DECLARE @IsProfileCompleted BIT = 0;
    IF @EffectiveFirstName IS NOT NULL 
       AND @EffectiveLastName IS NOT NULL 
       AND @EffectiveEmail IS NOT NULL 
       AND @EffectiveDob IS NOT NULL 
       AND @EffectiveGender IS NOT NULL
    BEGIN
        SET @IsProfileCompleted = 1;
    END

    -- Update Customer User Record
    UPDATE dbo.CUSTOMER_USERS
    SET 
        FIRST_NAME = @EffectiveFirstName,
        LAST_NAME = @EffectiveLastName,
        EMAIL = @EffectiveEmail,
        DOB = @EffectiveDob,
        GENDER = @EffectiveGender,
        PROFILE_IMAGE_URL = ISNULL(@CleanProfileImageUrl, PROFILE_IMAGE_URL),
        LANGUAGE_CODE = ISNULL(@CleanLanguageCode, LANGUAGE_CODE),
        ELIGIBLE_FOR_ORDER = @EligibleForOrder,
        IS_PROFILE_COMPLETED = @IsProfileCompleted,
        UPDATED_AT = @CurrentUtc
    WHERE USER_ID = @USER_ID;

    -- Return updated profile
    EXEC dbo.PR_CUSTOMER_GET_PROFILE @USER_ID = @USER_ID;
END;
GO
