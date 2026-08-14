-- =============================================================================
-- 0003_Create_Doc_Numbering_System.sql
-- M_DOC_NO, LASTDOCNO, LOCALDATE(), PR_GET_NEXT_DOC_NO, fn_NEXTDOCNO & CUSTOMER DOC_NO
-- =============================================================================

-- 1. COMPANY_CONFIG TABLE
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'COMPANY_CONFIG')
BEGIN
    CREATE TABLE dbo.COMPANY_CONFIG
    (
        COMPANY_CONFIG_ID   BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        COMPANY_CODE        VARCHAR(50) NOT NULL CONSTRAINT UQ_COMPANY_CONFIG_CODE UNIQUE,
        COMPANY_NAME        NVARCHAR(150) NOT NULL,
        IS_ACTIVE           BIT NOT NULL DEFAULT 1,
        CREATED_AT          DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UPDATED_AT          DATETIME2 NULL
    );

    INSERT INTO dbo.COMPANY_CONFIG (COMPANY_CODE, COMPANY_NAME, IS_ACTIVE)
    VALUES ('AL_AZIMA', 'Al Azima Meat Delivery', 1);
END
GO

-- 2. M_DOC_NO TABLE
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'M_DOC_NO')
BEGIN
    CREATE TABLE dbo.M_DOC_NO
    (
        M_DOC_NO_ID                 BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        MDOC                        VARCHAR(20) NOT NULL,
        DOCTYPE                     VARCHAR(20) NOT NULL CONSTRAINT UQ_M_DOC_NO_DOCTYPE UNIQUE,
        DESCRIPTION                 NVARCHAR(150) NOT NULL,
        COMPANY_CONFIG_ID           BIGINT NULL CONSTRAINT FK_M_DOC_NO_COMPANY REFERENCES dbo.COMPANY_CONFIG(COMPANY_CONFIG_ID),
        PREFIX                      VARCHAR(20) NULL,
        SUFFIX                      VARCHAR(20) NULL,
        DIGIT_NO                    INT NOT NULL,
        START_DOCNO                 BIGINT NOT NULL DEFAULT 0,
        PERIODWISE_YN               CHAR(1) NOT NULL DEFAULT 'N',
        PERIOD_TYPE                 VARCHAR(20) NULL DEFAULT 'NONE',
        DOC_PRINT                   VARCHAR(100) NULL,
        IS_ACTIVE                   BIT NOT NULL DEFAULT 1,
        CREATED_BY_ADMIN_USER_ID    BIGINT NULL,
        CREATED_AT                  DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UPDATED_AT                  DATETIME2 NULL
    );
END
GO

-- 3. LASTDOCNO TABLE
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'LASTDOCNO')
BEGIN
    CREATE TABLE dbo.LASTDOCNO
    (
        DOCTYPE                 VARCHAR(20) NOT NULL,
        PERIOD_KEY              VARCHAR(20) NOT NULL,
        DOCNO                   BIGINT NOT NULL,
        LAST_GENERATED_DOC_NO   VARCHAR(50) NULL,
        LAST_GENERATED_AT       DATETIME2 NULL,
        UPDATED_AT              DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        ROW_VERSION             ROWVERSION NOT NULL,
        CONSTRAINT PK_LASTDOCNO PRIMARY KEY (DOCTYPE, PERIOD_KEY),
        CONSTRAINT FK_LASTDOCNO_MDOC FOREIGN KEY (DOCTYPE) REFERENCES dbo.M_DOC_NO(DOCTYPE)
    );
END
GO

-- 4. SEED DEFAULT M_DOC_NO CONFIGURATIONS
DECLARE @DefaultCompanyId BIGINT;
SELECT TOP 1 @DefaultCompanyId = COMPANY_CONFIG_ID FROM dbo.COMPANY_CONFIG WHERE COMPANY_CODE = 'AL_AZIMA';

IF NOT EXISTS (SELECT 1 FROM dbo.M_DOC_NO WHERE DOCTYPE = 'CUS1')
    INSERT INTO dbo.M_DOC_NO (MDOC, DOCTYPE, DESCRIPTION, COMPANY_CONFIG_ID, PREFIX, SUFFIX, DIGIT_NO, START_DOCNO, PERIODWISE_YN, PERIOD_TYPE, IS_ACTIVE)
    VALUES ('CUS', 'CUS1', 'Customer Registration Number', @DefaultCompanyId, 'CUS', NULL, 10, 0, 'N', 'NONE', 1);

IF NOT EXISTS (SELECT 1 FROM dbo.M_DOC_NO WHERE DOCTYPE = 'ORD1')
    INSERT INTO dbo.M_DOC_NO (MDOC, DOCTYPE, DESCRIPTION, COMPANY_CONFIG_ID, PREFIX, SUFFIX, DIGIT_NO, START_DOCNO, PERIODWISE_YN, PERIOD_TYPE, IS_ACTIVE)
    VALUES ('ORD', 'ORD1', 'Customer Sales Order', @DefaultCompanyId, 'ORD', NULL, 12, 0, 'N', 'NONE', 1);

IF NOT EXISTS (SELECT 1 FROM dbo.M_DOC_NO WHERE DOCTYPE = 'INV1')
    INSERT INTO dbo.M_DOC_NO (MDOC, DOCTYPE, DESCRIPTION, COMPANY_CONFIG_ID, PREFIX, SUFFIX, DIGIT_NO, START_DOCNO, PERIODWISE_YN, PERIOD_TYPE, IS_ACTIVE)
    VALUES ('INV', 'INV1', 'Tax Invoice', @DefaultCompanyId, 'INV', NULL, 12, 0, 'N', 'NONE', 1);

IF NOT EXISTS (SELECT 1 FROM dbo.M_DOC_NO WHERE DOCTYPE = 'PAY1')
    INSERT INTO dbo.M_DOC_NO (MDOC, DOCTYPE, DESCRIPTION, COMPANY_CONFIG_ID, PREFIX, SUFFIX, DIGIT_NO, START_DOCNO, PERIODWISE_YN, PERIOD_TYPE, IS_ACTIVE)
    VALUES ('PAY', 'PAY1', 'Customer Payment Transaction', @DefaultCompanyId, 'PAY', NULL, 12, 0, 'N', 'NONE', 1);

IF NOT EXISTS (SELECT 1 FROM dbo.M_DOC_NO WHERE DOCTYPE = 'REF1')
    INSERT INTO dbo.M_DOC_NO (MDOC, DOCTYPE, DESCRIPTION, COMPANY_CONFIG_ID, PREFIX, SUFFIX, DIGIT_NO, START_DOCNO, PERIODWISE_YN, PERIOD_TYPE, IS_ACTIVE)
    VALUES ('REF', 'REF1', 'Customer Refund Transaction', @DefaultCompanyId, 'REF', NULL, 12, 0, 'N', 'NONE', 1);

IF NOT EXISTS (SELECT 1 FROM dbo.M_DOC_NO WHERE DOCTYPE = 'CRT1')
    INSERT INTO dbo.M_DOC_NO (MDOC, DOCTYPE, DESCRIPTION, COMPANY_CONFIG_ID, PREFIX, SUFFIX, DIGIT_NO, START_DOCNO, PERIODWISE_YN, PERIOD_TYPE, IS_ACTIVE)
    VALUES ('CRT', 'CRT1', 'Shopping Cart Number', @DefaultCompanyId, 'CRT', NULL, 12, 0, 'N', 'NONE', 1);

IF NOT EXISTS (SELECT 1 FROM dbo.M_DOC_NO WHERE DOCTYPE = 'STK1')
    INSERT INTO dbo.M_DOC_NO (MDOC, DOCTYPE, DESCRIPTION, COMPANY_CONFIG_ID, PREFIX, SUFFIX, DIGIT_NO, START_DOCNO, PERIODWISE_YN, PERIOD_TYPE, IS_ACTIVE)
    VALUES ('STK', 'STK1', 'Inventory Stock Transaction', @DefaultCompanyId, 'STK', NULL, 12, 0, 'N', 'NONE', 1);

IF NOT EXISTS (SELECT 1 FROM dbo.M_DOC_NO WHERE DOCTYPE = 'CPN1')
    INSERT INTO dbo.M_DOC_NO (MDOC, DOCTYPE, DESCRIPTION, COMPANY_CONFIG_ID, PREFIX, SUFFIX, DIGIT_NO, START_DOCNO, PERIODWISE_YN, PERIOD_TYPE, IS_ACTIVE)
    VALUES ('CPN', 'CPN1', 'Coupon Usage Record', @DefaultCompanyId, 'CPN', NULL, 12, 0, 'N', 'NONE', 1);

IF NOT EXISTS (SELECT 1 FROM dbo.M_DOC_NO WHERE DOCTYPE = 'NTF1')
    INSERT INTO dbo.M_DOC_NO (MDOC, DOCTYPE, DESCRIPTION, COMPANY_CONFIG_ID, PREFIX, SUFFIX, DIGIT_NO, START_DOCNO, PERIODWISE_YN, PERIOD_TYPE, IS_ACTIVE)
    VALUES ('NTF', 'NTF1', 'Notification Log', @DefaultCompanyId, 'NTF', NULL, 12, 0, 'N', 'NONE', 1);
GO

-- 5. LOCALDATE FUNCTION
CREATE OR ALTER FUNCTION dbo.LOCALDATE()
RETURNS DATETIME2
AS
BEGIN
    RETURN DATEADD(MINUTE, 240, SYSUTCDATETIME());
END;
GO

-- 6. PR_GET_NEXT_DOC_NO (Safe Concurrency-Locked Number Generator)
CREATE OR ALTER PROCEDURE dbo.PR_GET_NEXT_DOC_NO
(
    @DOCTYPE VARCHAR(20),
    @DOC_NO  VARCHAR(50) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @PREFIX VARCHAR(20),
        @SUFFIX VARCHAR(20),
        @DIGIT_NO INT,
        @START_DOCNO BIGINT,
        @PERIODWISE_YN CHAR(1),
        @PERIOD_TYPE VARCHAR(20),
        @PERIOD_KEY VARCHAR(20),
        @CURRENT_DOCNO BIGINT,
        @NEXT_DOCNO BIGINT,
        @NUMBER_LENGTH INT,
        @LOCAL_DATE DATETIME2;

    SELECT
        @PREFIX = ISNULL(PREFIX, ''),
        @SUFFIX = ISNULL(SUFFIX, ''),
        @DIGIT_NO = DIGIT_NO,
        @START_DOCNO = START_DOCNO,
        @PERIODWISE_YN = PERIODWISE_YN,
        @PERIOD_TYPE = PERIOD_TYPE
    FROM dbo.M_DOC_NO
    WHERE DOCTYPE = @DOCTYPE
      AND IS_ACTIVE = 1;

    IF @DIGIT_NO IS NULL
        THROW 50001, 'Invalid or inactive DOCTYPE.', 1;

    SET @LOCAL_DATE = dbo.LOCALDATE();

    SET @PERIOD_KEY =
        CASE
            WHEN @PERIODWISE_YN = 'N' THEN 'ALL'
            WHEN @PERIOD_TYPE = 'YEARLY'
                THEN CONVERT(VARCHAR(4), YEAR(@LOCAL_DATE))
            WHEN @PERIOD_TYPE = 'MONTHLY'
                THEN CONVERT(VARCHAR(4), YEAR(@LOCAL_DATE))
                     + RIGHT('0' + CONVERT(VARCHAR(2), MONTH(@LOCAL_DATE)), 2)
            ELSE 'ALL'
        END;

    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    BEGIN TRANSACTION;

    SELECT @CURRENT_DOCNO = DOCNO
    FROM dbo.LASTDOCNO WITH (UPDLOCK, HOLDLOCK)
    WHERE DOCTYPE = @DOCTYPE
      AND PERIOD_KEY = @PERIOD_KEY;

    IF @CURRENT_DOCNO IS NULL
    BEGIN
        SET @CURRENT_DOCNO = ISNULL(@START_DOCNO, 0);

        INSERT INTO dbo.LASTDOCNO
        (
            DOCTYPE,
            PERIOD_KEY,
            DOCNO,
            UPDATED_AT
        )
        VALUES
        (
            @DOCTYPE,
            @PERIOD_KEY,
            @CURRENT_DOCNO,
            SYSUTCDATETIME()
        );
    END;

    SET @NEXT_DOCNO = @CURRENT_DOCNO + 1;
    SET @NUMBER_LENGTH = @DIGIT_NO - LEN(@PREFIX) - LEN(@SUFFIX);

    IF @NUMBER_LENGTH <= 0
        THROW 50002, 'Invalid DIGIT_NO / PREFIX / SUFFIX configuration.', 1;

    IF LEN(CONVERT(VARCHAR(30), @NEXT_DOCNO)) > @NUMBER_LENGTH
        THROW 50003, 'Document number sequence exceeded configured length.', 1;

    SET @DOC_NO =
          @PREFIX
        + RIGHT(REPLICATE('0', @NUMBER_LENGTH) + CONVERT(VARCHAR(30), @NEXT_DOCNO), @NUMBER_LENGTH)
        + @SUFFIX;

    UPDATE dbo.LASTDOCNO
    SET
        DOCNO = @NEXT_DOCNO,
        LAST_GENERATED_DOC_NO = @DOC_NO,
        LAST_GENERATED_AT = SYSUTCDATETIME(),
        UPDATED_AT = SYSUTCDATETIME()
    WHERE DOCTYPE = @DOCTYPE
      AND PERIOD_KEY = @PERIOD_KEY;

    COMMIT TRANSACTION;
END;
GO

-- 7. fn_NEXTDOCNO (Preview function only)
CREATE OR ALTER FUNCTION dbo.fn_NEXTDOCNO
(
    @DOCTYPE NVARCHAR(20)
)
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @RESULT NVARCHAR(50);
    DECLARE @LOCAL_DATE DATETIME2 = dbo.LOCALDATE();

    SELECT @RESULT =
        ISNULL(M.PREFIX, '')
        + RIGHT(
            REPLICATE(
                '0',
                M.DIGIT_NO
                - LEN(ISNULL(M.PREFIX, ''))
                - LEN(ISNULL(M.SUFFIX, ''))
            )
            + CONVERT(
                VARCHAR(30),
                ISNULL(L.DOCNO, M.START_DOCNO) + 1
            ),
            M.DIGIT_NO
            - LEN(ISNULL(M.PREFIX, ''))
            - LEN(ISNULL(M.SUFFIX, ''))
        )
        + ISNULL(M.SUFFIX, '')
    FROM dbo.M_DOC_NO M
    LEFT JOIN dbo.LASTDOCNO L
        ON L.DOCTYPE = M.DOCTYPE
       AND L.PERIOD_KEY =
            CASE
                WHEN M.PERIODWISE_YN = 'N' THEN 'ALL'
                WHEN M.PERIOD_TYPE = 'YEARLY'
                    THEN CONVERT(VARCHAR(4), YEAR(@LOCAL_DATE))
                WHEN M.PERIOD_TYPE = 'MONTHLY'
                    THEN CONVERT(VARCHAR(4), YEAR(@LOCAL_DATE))
                         + RIGHT('0' + CONVERT(VARCHAR(2), MONTH(@LOCAL_DATE)), 2)
                ELSE 'ALL'
            END
    WHERE M.DOCTYPE = @DOCTYPE
      AND M.IS_ACTIVE = 1;

    RETURN @RESULT;
END;
GO

-- 8. fn_NEXTDOCNO_COMPANY (Preview function with Company Code)
CREATE OR ALTER FUNCTION dbo.fn_NEXTDOCNO_COMPANY
(
    @DOCTYPE NVARCHAR(20),
    @COMPANY_CODE VARCHAR(50)
)
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @RESULT NVARCHAR(50);
    DECLARE @LOCAL_DATE DATETIME2 = dbo.LOCALDATE();

    SELECT @RESULT =
        ISNULL(M.PREFIX, '')
        + RIGHT(
            REPLICATE(
                '0',
                M.DIGIT_NO
                - LEN(ISNULL(M.PREFIX, ''))
                - LEN(ISNULL(M.SUFFIX, ''))
            )
            + CONVERT(
                VARCHAR(30),
                ISNULL(L.DOCNO, M.START_DOCNO) + 1
            ),
            M.DIGIT_NO
            - LEN(ISNULL(M.PREFIX, ''))
            - LEN(ISNULL(M.SUFFIX, ''))
        )
        + ISNULL(M.SUFFIX, '')
    FROM dbo.M_DOC_NO M
    INNER JOIN dbo.COMPANY_CONFIG C
        ON C.COMPANY_CONFIG_ID = M.COMPANY_CONFIG_ID
    LEFT JOIN dbo.LASTDOCNO L
        ON L.DOCTYPE = M.DOCTYPE
       AND L.PERIOD_KEY =
            CASE
                WHEN M.PERIODWISE_YN = 'N' THEN 'ALL'
                WHEN M.PERIOD_TYPE = 'YEARLY'
                    THEN CONVERT(VARCHAR(4), YEAR(@LOCAL_DATE))
                WHEN M.PERIOD_TYPE = 'MONTHLY'
                    THEN CONVERT(VARCHAR(4), YEAR(@LOCAL_DATE))
                         + RIGHT('0' + CONVERT(VARCHAR(2), MONTH(@LOCAL_DATE)), 2)
                ELSE 'ALL'
            END
    WHERE M.DOCTYPE = @DOCTYPE
      AND C.COMPANY_CODE = @COMPANY_CODE
      AND M.IS_ACTIVE = 1;

    RETURN @RESULT;
END;
GO

-- 9. ADD DOCTYPE AND DOC_NO TO USERS (CUSTOMERS) TABLE
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.USERS') AND name = 'DOCTYPE')
BEGIN
    ALTER TABLE dbo.USERS ADD DOCTYPE VARCHAR(20) NULL;
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.USERS') AND name = 'DOC_NO')
BEGIN
    ALTER TABLE dbo.USERS ADD DOC_NO VARCHAR(50) NULL;
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_USERS_DOCTYPE_DOCNO' AND object_id = OBJECT_ID('dbo.USERS'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_USERS_DOCTYPE_DOCNO
    ON dbo.USERS(DOCTYPE, DOC_NO)
    WHERE DOC_NO IS NOT NULL;
END
GO

-- 10. UPDATE PR_AUTH_VERIFY_OTP_AND_REGISTER_CUSTOMER TO ALLOCATE CUSTOMER DOC_NO
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
        ORDER BY OTP_ID DESC;
    END

    IF @OtpId IS NULL
    BEGIN
        RAISERROR('No pending OTP request found.', 16, 1);
        RETURN;
    END

    IF @OtpStatus <> 'PENDING'
    BEGIN
        RAISERROR('OTP is no longer valid.', 16, 1);
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

    IF SYSUTCDATETIME() > @OtpExpiresAt
    BEGIN
        UPDATE dbo.OTP_VERIFICATIONS 
        SET OTP_STATUS = 'EXPIRED', UPDATED_AT = SYSUTCDATETIME()
        WHERE OTP_ID = @OtpId;

        RAISERROR('OTP has expired. Please request a new OTP.', 16, 1);
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
    DECLARE @CustomerRoleId INT;
    DECLARE @IsNewUser BIT = 0;

    SELECT @UserId = USER_ID 
    FROM dbo.USERS 
    WHERE COUNTRY_CODE = @CountryCode AND MOBILE_NUMBER = @MobileNumber;

    IF @UserId IS NULL
    BEGIN
        SET @IsNewUser = 1;

        -- Allocate Customer Document Number
        DECLARE @CustomerDocNo VARCHAR(50);
        EXEC dbo.PR_GET_NEXT_DOC_NO
            @DOCTYPE = 'CUS1',
            @DOC_NO = @CustomerDocNo OUTPUT;

        INSERT INTO dbo.USERS
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
            @CustomerDocNo,
            NULL,
            NULL,
            ISNULL(@LanguageCode, 'EN'),
            1,
            0,
            0,
            'ACTIVE',
            SYSUTCDATETIME(),
            SYSUTCDATETIME()
        );

        SET @UserId = SCOPE_IDENTITY();

        SELECT @CustomerRoleId = ROLE_ID 
        FROM dbo.ROLES 
        WHERE ROLE_CODE = 'CUSTOMER';

        IF @CustomerRoleId IS NOT NULL
        BEGIN
            INSERT INTO dbo.USER_ROLES (USER_ID, ROLE_ID, IS_ACTIVE, ASSIGNED_AT)
            VALUES (@UserId, @CustomerRoleId, 1, SYSUTCDATETIME());
        END
    END
    ELSE
    BEGIN
        UPDATE dbo.USERS
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
        u.IS_PROFILE_COMPLETED AS IsProfileCompleted,
        @IsNewUser AS IsNewUser,
        r.ROLE_CODE AS RoleCode
    FROM dbo.USERS u
    LEFT JOIN dbo.USER_ROLES ur ON u.USER_ID = ur.USER_ID AND ur.IS_ACTIVE = 1
    LEFT JOIN dbo.ROLES r ON ur.ROLE_ID = r.ROLE_ID
    WHERE u.USER_ID = @UserId;
END;
GO
