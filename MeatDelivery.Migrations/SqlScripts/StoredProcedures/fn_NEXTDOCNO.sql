-- =============================================================================
-- FUNCTION: dbo.fn_NEXTDOCNO
-- Description: Preview / read function for next formatted document number.
-- Note: Preview only. Final allocation must use PR_GET_NEXT_DOC_NO.
-- =============================================================================

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
