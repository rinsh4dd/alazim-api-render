-- =============================================================================
-- STORED PROCEDURE: dbo.PR_GET_TEMPLATE_GROUP_MAPPINGS
-- Description: Retrieves mapped customization groups for a template (or list all mappings).
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_GET_TEMPLATE_GROUP_MAPPINGS
(
    @PAGE_NUMBER              INT           = 1,
    @PAGE_SIZE                INT           = 10,
    @CUSTOMIZATION_TEMPLATE_ID  BIGINT      = NULL,
    @CUSTOMIZATION_GROUP_ID     BIGINT      = NULL,
    @IS_ACTIVE                  BIT         = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @PAGE_NUMBER IS NULL OR @PAGE_NUMBER < 1 SET @PAGE_NUMBER = 1;
    IF @PAGE_SIZE IS NULL OR @PAGE_SIZE < 1 SET @PAGE_SIZE = 10;
    IF @PAGE_SIZE > 100 SET @PAGE_SIZE = 100;

    -- Result Set 1: Total Record Count
    SELECT COUNT(1) AS TotalRecords
    FROM dbo.TEMPLATE_GROUP_MAPPING tgm
    JOIN dbo.CUSTOMIZATION_TEMPLATES ct ON tgm.CUSTOMIZATION_TEMPLATE_ID = ct.CUSTOMIZATION_TEMPLATE_ID
    JOIN dbo.CUSTOMIZATION_GROUPS cg ON tgm.CUSTOMIZATION_GROUP_ID = cg.CUSTOMIZATION_GROUP_ID
    WHERE (@CUSTOMIZATION_TEMPLATE_ID IS NULL OR tgm.CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID)
      AND (@CUSTOMIZATION_GROUP_ID IS NULL OR tgm.CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID)
      AND (@IS_ACTIVE IS NULL OR tgm.IS_ACTIVE = @IS_ACTIVE);

    -- Result Set 2: Paged Template Group Mappings
    SELECT 
        tgm.TEMPLATE_GROUP_MAPPING_ID   AS TemplateGroupMappingId,
        tgm.CUSTOMIZATION_TEMPLATE_ID   AS CustomizationTemplateId,
        ct.TEMPLATE_NAME_EN             AS TemplateNameEn,
        ct.TEMPLATE_NAME_AR             AS TemplateNameAr,
        tgm.CUSTOMIZATION_GROUP_ID      AS CustomizationGroupId,
        cg.GROUP_CODE                   AS GroupCode,
        cg.GROUP_NAME_EN                AS GroupNameEn,
        cg.GROUP_NAME_AR                AS GroupNameAr,
        cg.IS_ADDITIONAL_PRICE_AVAILABLEAS IsAdditionalPriceAvailable,
        tgm.IS_ACTIVE                   AS IsActive,
        tgm.CREATED_AT                  AS CreatedAt,
        tgm.UPDATED_AT                  AS UpdatedAt
    FROM dbo.TEMPLATE_GROUP_MAPPING tgm
    JOIN dbo.CUSTOMIZATION_TEMPLATES ct ON tgm.CUSTOMIZATION_TEMPLATE_ID = ct.CUSTOMIZATION_TEMPLATE_ID
    JOIN dbo.CUSTOMIZATION_GROUPS cg ON tgm.CUSTOMIZATION_GROUP_ID = cg.CUSTOMIZATION_GROUP_ID
    WHERE (@CUSTOMIZATION_TEMPLATE_ID IS NULL OR tgm.CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID)
      AND (@CUSTOMIZATION_GROUP_ID IS NULL OR tgm.CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID)
      AND (@IS_ACTIVE IS NULL OR tgm.IS_ACTIVE = @IS_ACTIVE)
    ORDER BY tgm.TEMPLATE_GROUP_MAPPING_ID ASC
    OFFSET (@PAGE_NUMBER - 1) * @PAGE_SIZE ROWS
    FETCH NEXT @PAGE_SIZE ROWS ONLY;
END;
GO
