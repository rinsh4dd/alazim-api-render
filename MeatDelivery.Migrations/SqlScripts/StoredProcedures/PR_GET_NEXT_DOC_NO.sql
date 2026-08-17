-- =============================================================================
-- STORED PROCEDURE: dbo.PR_GET_NEXT_DOC_NO
-- Description: Safe, concurrency-locked document number generator.
-- Allocates next numeric sequence and returns complete formatted DOC_NO.
-- =============================================================================

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
