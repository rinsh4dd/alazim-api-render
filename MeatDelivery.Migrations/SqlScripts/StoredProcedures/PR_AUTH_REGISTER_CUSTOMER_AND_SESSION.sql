-- =============================================================================
-- STORED PROCEDURE: dbo.PR_AUTH_REGISTER_CUSTOMER_AND_SESSION
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_AUTH_REGISTER_CUSTOMER_AND_SESSION
    @CountryCode VARCHAR(10),
    @MobileNumber VARCHAR(20),
    @FullName NVARCHAR(150) = NULL,
    @LanguageCode VARCHAR(10) = 'EN',
    @RefreshTokenHash VARCHAR(500),
    @DeviceId VARCHAR(200) = NULL,
    @DeviceType VARCHAR(30) = NULL,
    @IpAddress VARCHAR(45) = NULL,
    @SessionExpiresAt DATETIME2
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

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
        SET LAST_LOGIN_AT = SYSUTCDATETIME(),
            UPDATED_AT = SYSUTCDATETIME()
        WHERE USER_ID = @UserId;
    END

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
