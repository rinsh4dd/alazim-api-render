-- =============================================================================
-- Migration: 0033_Ensure_PRD1_DocType_In_M_DOC_NO.sql
-- Description: Unconditionally ensures PRD1 DOCTYPE is present and active in dbo.M_DOC_NO.
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM dbo.M_DOC_NO WHERE DOCTYPE = 'PRD1')
BEGIN
    DECLARE @CompanyId BIGINT = (SELECT TOP 1 COMPANY_CONFIG_ID FROM dbo.COMPANY_CONFIG WHERE COMPANY_CODE = 'AL_AZIMA');

    INSERT INTO dbo.M_DOC_NO
    (
        MDOC, DOCTYPE, DESCRIPTION, COMPANY_CONFIG_ID,
        PREFIX, SUFFIX, DIGIT_NO, START_DOCNO,
        PERIODWISE_YN, PERIOD_TYPE, IS_ACTIVE
    )
    VALUES
    (
        'PRD', 'PRD1', 'Product Document Number', @CompanyId,
        'PRD', NULL, 10, 0,
        'N', 'NONE', 1
    );
END
ELSE
BEGIN
    UPDATE dbo.M_DOC_NO
    SET IS_ACTIVE = 1
    WHERE DOCTYPE = 'PRD1';
END;
GO
