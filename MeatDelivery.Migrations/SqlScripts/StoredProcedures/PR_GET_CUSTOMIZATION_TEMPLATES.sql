-- =============================================================================
-- STORED PROCEDURE: dbo.PR_GET_CUSTOMIZATION_TEMPLATES
-- Description: Retrieves paginated customization templates supporting search (via @SEARCH),
--              filtering by CustomizationTemplateId (GetById) and IsActive status.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_GET_CUSTOMIZATION_TEMPLATES
(
    @PAGE_NUMBER                INT           = 1,
    @PAGE_SIZE                  INT           = 10,
    @SEARCH                     NVARCHAR(150) = NULL,
    @CUSTOMIZATION_TEMPLATE_ID  BIGINT        = NULL,
    @IS_ACTIVE                  BIT           = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Sanitize pagination parameters
    IF @PAGE_NUMBER IS NULL OR @PAGE_NUMBER < 1 SET @PAGE_NUMBER = 1;
    IF @PAGE_SIZE IS NULL OR @PAGE_SIZE < 1 SET @PAGE_SIZE = 10;
    IF @PAGE_SIZE > 100 SET @PAGE_SIZE = 100;

    SET @SEARCH = LTRIM(RTRIM(@SEARCH));
    IF @SEARCH = '' SET @SEARCH = NULL;

    -- Result Set 1: Total Record Count
    SELECT COUNT(1) AS TotalRecords
    FROM dbo.CUSTOMIZATION_TEMPLATES ct
    WHERE (@SEARCH IS NULL 
           OR ct.DOC_NO LIKE '%' + @SEARCH + '%'
           OR ct.TEMPLATE_NAME_EN LIKE '%' + @SEARCH + '%'
           OR ct.TEMPLATE_NAME_AR LIKE '%' + @SEARCH + '%'
           OR ct.DESCRIPTION_EN LIKE '%' + @SEARCH + '%'
           OR ct.DESCRIPTION_AR LIKE '%' + @SEARCH + '%')
      AND (@CUSTOMIZATION_TEMPLATE_ID IS NULL OR ct.CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID)
      AND (@IS_ACTIVE IS NULL OR ct.IS_ACTIVE = @IS_ACTIVE);

    -- Result Set 2: Paged Customization Templates
    SELECT 
        ct.CUSTOMIZATION_TEMPLATE_ID   AS CustomizationTemplateId,
        ct.DOC_NO                      AS DocNo,
        ct.DOC_TYPE                    AS DocType,
        ct.TEMPLATE_NAME_EN            AS TemplateNameEn,
        ct.TEMPLATE_NAME_AR            AS TemplateNameAr,
        ct.DESCRIPTION_EN              AS DescriptionEn,
        ct.DESCRIPTION_AR              AS DescriptionAr,
        ct.IS_ACTIVE                   AS IsActive,
        ct.CREATED_AT                  AS CreatedAt,
        ct.UPDATED_AT                  AS UpdatedAt
    FROM dbo.CUSTOMIZATION_TEMPLATES ct
    WHERE (@SEARCH IS NULL 
           OR ct.DOC_NO LIKE '%' + @SEARCH + '%'
           OR ct.TEMPLATE_NAME_EN LIKE '%' + @SEARCH + '%'
           OR ct.TEMPLATE_NAME_AR LIKE '%' + @SEARCH + '%'
           OR ct.DESCRIPTION_EN LIKE '%' + @SEARCH + '%'
           OR ct.DESCRIPTION_AR LIKE '%' + @SEARCH + '%')
      AND (@CUSTOMIZATION_TEMPLATE_ID IS NULL OR ct.CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID)
      AND (@IS_ACTIVE IS NULL OR ct.IS_ACTIVE = @IS_ACTIVE)
    ORDER BY ct.CUSTOMIZATION_TEMPLATE_ID DESC
    OFFSET (@PAGE_NUMBER - 1) * @PAGE_SIZE ROWS
    FETCH NEXT @PAGE_SIZE ROWS ONLY;
END;
GO
