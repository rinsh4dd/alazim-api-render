-- =============================================================================
-- STORED PROCEDURE: dbo.PR_GET_CUSTOMIZATION_GROUPS
-- Description: Retrieves paginated customization groups supporting search (via @SEARCH),
--              filtering by CustomizationGroupId (GetById) and IsActive status.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_GET_CUSTOMIZATION_GROUPS
(
    @PAGE_NUMBER             INT           = 1,
    @PAGE_SIZE               INT           = 10,
    @SEARCH                  NVARCHAR(150) = NULL,
    @CUSTOMIZATION_GROUP_ID  BIGINT        = NULL,
    @IS_ACTIVE               BIT           = NULL
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
    FROM dbo.CUSTOMIZATION_GROUPS cg
    WHERE (@SEARCH IS NULL 
           OR cg.GROUP_CODE LIKE '%' + @SEARCH + '%'
           OR cg.GROUP_NAME_EN LIKE '%' + @SEARCH + '%'
           OR cg.GROUP_NAME_AR LIKE '%' + @SEARCH + '%')
      AND (@CUSTOMIZATION_GROUP_ID IS NULL OR cg.CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID)
      AND (@IS_ACTIVE IS NULL OR cg.IS_ACTIVE = @IS_ACTIVE);

    -- Result Set 2: Paged Customization Groups
    SELECT 
        cg.CUSTOMIZATION_GROUP_ID          AS CustomizationGroupId,
        cg.GROUP_CODE                      AS GroupCode,
        cg.GROUP_NAME_EN                   AS GroupNameEn,
        cg.GROUP_NAME_AR                   AS GroupNameAr,
        cg.IS_ADDITIONAL_PRICE_AVAILABLE   AS IsAdditionalPriceAvailable,
        cg.PRICING_TYPE                    AS PricingType,
        cg.IS_CUSTOM_DATA_ALLOWED          AS IsCustomDataAllowed,
        cg.IS_ACTIVE                       AS IsActive,
        cg.CREATED_AT                      AS CreatedAt,
        cg.UPDATED_AT                      AS UpdatedAt
    FROM dbo.CUSTOMIZATION_GROUPS cg
    WHERE (@SEARCH IS NULL 
           OR cg.GROUP_CODE LIKE '%' + @SEARCH + '%'
           OR cg.GROUP_NAME_EN LIKE '%' + @SEARCH + '%'
           OR cg.GROUP_NAME_AR LIKE '%' + @SEARCH + '%')
      AND (@CUSTOMIZATION_GROUP_ID IS NULL OR cg.CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID)
      AND (@IS_ACTIVE IS NULL OR cg.IS_ACTIVE = @IS_ACTIVE)
    ORDER BY cg.CUSTOMIZATION_GROUP_ID DESC
    OFFSET (@PAGE_NUMBER - 1) * @PAGE_SIZE ROWS
    FETCH NEXT @PAGE_SIZE ROWS ONLY;

    -- Result Set 3: Customization Options (only when @CUSTOMIZATION_GROUP_ID IS NOT NULL)
    IF @CUSTOMIZATION_GROUP_ID IS NOT NULL
    BEGIN
        SELECT 
            co.CUSTOMIZATION_OPTION_ID   AS CustomizationOptionId,
            co.CUSTOMIZATION_GROUP_ID    AS CustomizationGroupId,
            cg.GROUP_NAME_EN             AS GroupNameEn,
            cg.GROUP_NAME_AR             AS GroupNameAr,
            co.OPTION_CODE               AS OptionCode,
            co.OPTION_NAME_EN            AS OptionNameEn,
            co.OPTION_NAME_AR            AS OptionNameAr,
            co.PRICING_VALUE             AS PricingValue,
            co.IS_ACTIVE                 AS IsActive,
            co.CREATED_AT                AS CreatedAt,
            co.UPDATED_AT                AS UpdatedAt
        FROM dbo.CUSTOMIZATION_OPTIONS co
        JOIN dbo.CUSTOMIZATION_GROUPS cg ON co.CUSTOMIZATION_GROUP_ID = cg.CUSTOMIZATION_GROUP_ID
        WHERE co.CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID
          AND (@IS_ACTIVE IS NULL OR co.IS_ACTIVE = @IS_ACTIVE)
        ORDER BY co.CUSTOMIZATION_OPTION_ID ASC;
    END
END;
GO
