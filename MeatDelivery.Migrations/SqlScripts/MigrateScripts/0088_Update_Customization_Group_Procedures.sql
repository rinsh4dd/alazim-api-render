-- Migration Script: 0088_Update_Customization_Group_Procedures.sql
-- Description: Update stored procedures PR_SAVE_CUSTOMIZATION_GROUP, PR_GET_CUSTOMIZATION_GROUPS, and PR_GET_PRODUCT_CUSTOMIZATION_HIERARCHY to support PRICING_TYPE and PRICING_VALUE.

-- 1. Update PR_SAVE_CUSTOMIZATION_GROUP
EXEC('
CREATE OR ALTER PROCEDURE dbo.PR_SAVE_CUSTOMIZATION_GROUP
(
    @MODE                            VARCHAR(10),
    @CUSTOMIZATION_GROUP_ID          BIGINT        = NULL,
    @GROUP_CODE                      VARCHAR(50)   = NULL,
    @GROUP_NAME_EN                   NVARCHAR(150) = NULL,
    @GROUP_NAME_AR                   NVARCHAR(150) = NULL,
    @IS_ADDITIONAL_PRICE_AVAILABLE   BIT           = 0,
    @PRICING_TYPE                    VARCHAR(20)   = ''ADDITIONAL_PRICE'',
    @PRICING_VALUE                   DECIMAL(18,2) = 0.00,
    @IS_ACTIVE                       BIT           = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @MODE = UPPER(LTRIM(RTRIM(@MODE)));
    SET @GROUP_CODE = UPPER(LTRIM(RTRIM(@GROUP_CODE)));
    SET @GROUP_NAME_EN = LTRIM(RTRIM(@GROUP_NAME_EN));
    SET @GROUP_NAME_AR = LTRIM(RTRIM(@GROUP_NAME_AR));
    SET @PRICING_TYPE = ISNULL(NULLIF(UPPER(LTRIM(RTRIM(@PRICING_TYPE))), ''''), ''ADDITIONAL_PRICE'');

    IF @MODE = ''ADD''
    BEGIN
        IF @GROUP_CODE IS NULL OR @GROUP_CODE = ''''
        BEGIN
            RAISERROR(''Group code is required.'', 16, 1);
            RETURN;
        END;

        IF @GROUP_NAME_EN IS NULL OR @GROUP_NAME_EN = ''''
        BEGIN
            RAISERROR(''English group name is required.'', 16, 1);
            RETURN;
        END;

        IF @GROUP_NAME_AR IS NULL OR @GROUP_NAME_AR = ''''
        BEGIN
            RAISERROR(''Arabic group name is required.'', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_GROUPS WHERE UPPER(GROUP_CODE) = @GROUP_CODE)
        BEGIN
            RAISERROR(''Group code already exists.'', 16, 1);
            RETURN;
        END;

        INSERT INTO dbo.CUSTOMIZATION_GROUPS
        (
            GROUP_CODE,
            GROUP_NAME_EN,
            GROUP_NAME_AR,
            IS_ADDITIONAL_PRICE_AVAILABLE,
            PRICING_TYPE,
            PRICING_VALUE,
            IS_ACTIVE,
            CREATED_AT,
            UPDATED_AT
        )
        VALUES
        (
            @GROUP_CODE,
            @GROUP_NAME_EN,
            @GROUP_NAME_AR,
            ISNULL(@IS_ADDITIONAL_PRICE_AVAILABLE, 0),
            @PRICING_TYPE,
            ISNULL(@PRICING_VALUE, 0.00),
            ISNULL(@IS_ACTIVE, 1),
            SYSUTCDATETIME(),
            NULL
        );

        SET @CUSTOMIZATION_GROUP_ID = SCOPE_IDENTITY();

        SELECT 
            cg.CUSTOMIZATION_GROUP_ID          AS CustomizationGroupId,
            cg.GROUP_CODE                      AS GroupCode,
            cg.GROUP_NAME_EN                   AS GroupNameEn,
            cg.GROUP_NAME_AR                   AS GroupNameAr,
            cg.IS_ADDITIONAL_PRICE_AVAILABLE   AS IsAdditionalPriceAvailable,
            cg.PRICING_TYPE                    AS PricingType,
            cg.PRICING_VALUE                   AS PricingValue,
            cg.IS_ACTIVE                       AS IsActive,
            cg.CREATED_AT                      AS CreatedAt,
            cg.UPDATED_AT                      AS UpdatedAt
        FROM dbo.CUSTOMIZATION_GROUPS cg
        WHERE cg.CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID;

        RETURN;
    END;

    IF @MODE = ''EDIT''
    BEGIN
        IF @CUSTOMIZATION_GROUP_ID IS NULL OR @CUSTOMIZATION_GROUP_ID <= 0
        BEGIN
            RAISERROR(''Valid CustomizationGroupId is required for edit mode.'', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_GROUPS WHERE CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID)
        BEGIN
            RAISERROR(''Customization group not found.'', 16, 1);
            RETURN;
        END;

        IF @GROUP_CODE IS NULL OR @GROUP_CODE = ''''
        BEGIN
            RAISERROR(''Group code is required.'', 16, 1);
            RETURN;
        END;

        IF @GROUP_NAME_EN IS NULL OR @GROUP_NAME_EN = ''''
        BEGIN
            RAISERROR(''English group name is required.'', 16, 1);
            RETURN;
        END;

        IF @GROUP_NAME_AR IS NULL OR @GROUP_NAME_AR = ''''
        BEGIN
            RAISERROR(''Arabic group name is required.'', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_GROUPS WHERE UPPER(GROUP_CODE) = @GROUP_CODE AND CUSTOMIZATION_GROUP_ID <> @CUSTOMIZATION_GROUP_ID)
        BEGIN
            RAISERROR(''Group code already exists.'', 16, 1);
            RETURN;
        END;

        UPDATE dbo.CUSTOMIZATION_GROUPS
        SET 
            GROUP_CODE                    = @GROUP_CODE,
            GROUP_NAME_EN                 = @GROUP_NAME_EN,
            GROUP_NAME_AR                 = @GROUP_NAME_AR,
            IS_ADDITIONAL_PRICE_AVAILABLE = ISNULL(@IS_ADDITIONAL_PRICE_AVAILABLE, IS_ADDITIONAL_PRICE_AVAILABLE),
            PRICING_TYPE                  = ISNULL(@PRICING_TYPE, PRICING_TYPE),
            PRICING_VALUE                 = ISNULL(@PRICING_VALUE, PRICING_VALUE),
            IS_ACTIVE                     = ISNULL(@IS_ACTIVE, IS_ACTIVE),
            UPDATED_AT                    = SYSUTCDATETIME()
        WHERE CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID;

        SELECT 
            cg.CUSTOMIZATION_GROUP_ID          AS CustomizationGroupId,
            cg.GROUP_CODE                      AS GroupCode,
            cg.GROUP_NAME_EN                   AS GroupNameEn,
            cg.GROUP_NAME_AR                   AS GroupNameAr,
            cg.IS_ADDITIONAL_PRICE_AVAILABLE   AS IsAdditionalPriceAvailable,
            cg.PRICING_TYPE                    AS PricingType,
            cg.PRICING_VALUE                   AS PricingValue,
            cg.IS_ACTIVE                       AS IsActive,
            cg.CREATED_AT                      AS CreatedAt,
            cg.UPDATED_AT                      AS UpdatedAt
        FROM dbo.CUSTOMIZATION_GROUPS cg
        WHERE cg.CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID;

        RETURN;
    END;

    IF @MODE = ''DELETE''
    BEGIN
        IF @CUSTOMIZATION_GROUP_ID IS NULL OR @CUSTOMIZATION_GROUP_ID <= 0
        BEGIN
            RAISERROR(''Valid CustomizationGroupId is required for delete mode.'', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_GROUPS WHERE CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID)
        BEGIN
            RAISERROR(''Customization group not found.'', 16, 1);
            RETURN;
        END;

        DELETE FROM dbo.CUSTOMIZATION_GROUPS
        WHERE CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID;

        SELECT NULL AS CustomizationGroupId WHERE 1 = 0;
        RETURN;
    END;

    RAISERROR(''Invalid Mode specified. Use ADD, EDIT, or DELETE.'', 16, 1);
END;');
GO

-- 2. Update PR_GET_CUSTOMIZATION_GROUPS
EXEC('
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

    IF @PAGE_NUMBER IS NULL OR @PAGE_NUMBER < 1 SET @PAGE_NUMBER = 1;
    IF @PAGE_SIZE IS NULL OR @PAGE_SIZE < 1 SET @PAGE_SIZE = 10;
    IF @PAGE_SIZE > 100 SET @PAGE_SIZE = 100;

    SET @SEARCH = LTRIM(RTRIM(@SEARCH));
    IF @SEARCH = '''' SET @SEARCH = NULL;

    SELECT COUNT(1) AS TotalRecords
    FROM dbo.CUSTOMIZATION_GROUPS cg
    WHERE (@SEARCH IS NULL 
           OR cg.GROUP_CODE LIKE ''%'' + @SEARCH + ''%''
           OR cg.GROUP_NAME_EN LIKE ''%'' + @SEARCH + ''%''
           OR cg.GROUP_NAME_AR LIKE ''%'' + @SEARCH + ''%'')
      AND (@CUSTOMIZATION_GROUP_ID IS NULL OR cg.CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID)
      AND (@IS_ACTIVE IS NULL OR cg.IS_ACTIVE = @IS_ACTIVE);

    SELECT 
        cg.CUSTOMIZATION_GROUP_ID          AS CustomizationGroupId,
        cg.GROUP_CODE                      AS GroupCode,
        cg.GROUP_NAME_EN                   AS GroupNameEn,
        cg.GROUP_NAME_AR                   AS GroupNameAr,
        cg.IS_ADDITIONAL_PRICE_AVAILABLE   AS IsAdditionalPriceAvailable,
        cg.PRICING_TYPE                    AS PricingType,
        cg.PRICING_VALUE                   AS PricingValue,
        cg.IS_ACTIVE                       AS IsActive,
        cg.CREATED_AT                      AS CreatedAt,
        cg.UPDATED_AT                      AS UpdatedAt
    FROM dbo.CUSTOMIZATION_GROUPS cg
    WHERE (@SEARCH IS NULL 
           OR cg.GROUP_CODE LIKE ''%'' + @SEARCH + ''%''
           OR cg.GROUP_NAME_EN LIKE ''%'' + @SEARCH + ''%''
           OR cg.GROUP_NAME_AR LIKE ''%'' + @SEARCH + ''%'')
      AND (@CUSTOMIZATION_GROUP_ID IS NULL OR cg.CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID)
      AND (@IS_ACTIVE IS NULL OR cg.IS_ACTIVE = @IS_ACTIVE)
    ORDER BY cg.CUSTOMIZATION_GROUP_ID DESC
    OFFSET (@PAGE_NUMBER - 1) * @PAGE_SIZE ROWS
    FETCH NEXT @PAGE_SIZE ROWS ONLY;

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
            co.ADDITIONAL_PRICE          AS AdditionalPrice,
            co.IS_ACTIVE                 AS IsActive,
            co.CREATED_AT                AS CreatedAt,
            co.UPDATED_AT                AS UpdatedAt
        FROM dbo.CUSTOMIZATION_OPTIONS co
        JOIN dbo.CUSTOMIZATION_GROUPS cg ON co.CUSTOMIZATION_GROUP_ID = cg.CUSTOMIZATION_GROUP_ID
        WHERE co.CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID
          AND (@IS_ACTIVE IS NULL OR co.IS_ACTIVE = @IS_ACTIVE)
        ORDER BY co.CUSTOMIZATION_OPTION_ID ASC;
    END
END;');
GO

-- 3. Update PR_GET_PRODUCT_CUSTOMIZATION_HIERARCHY
EXEC('
CREATE OR ALTER PROCEDURE dbo.PR_GET_PRODUCT_CUSTOMIZATION_HIERARCHY
    @PRODUCT_ID BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        p.PRODUCT_ID AS ProductId,
        p.PRODUCT_NAME_EN AS ProductNameEn,
        p.PRODUCT_NAME_AR AS ProductNameAr,
        p.IS_CUSTOMIZABLE AS IsCustomizable,
        p.CUSTOMIZATION_TEMPLATE_ID AS CustomizationTemplateId
    FROM dbo.PRODUCTS p
    WHERE p.PRODUCT_ID = @PRODUCT_ID AND (p.IS_DELETED = 0 OR p.IS_DELETED IS NULL);

    SELECT TOP 1
        t.CUSTOMIZATION_TEMPLATE_ID AS CustomizationTemplateId,
        t.DOC_NO AS DocNo,
        t.TEMPLATE_NAME_EN AS TemplateNameEn,
        t.TEMPLATE_NAME_AR AS TemplateNameAr,
        t.DESCRIPTION_EN AS DescriptionEn,
        t.DESCRIPTION_AR AS DescriptionAr,
        t.IS_ACTIVE AS IsActive
    FROM dbo.CUSTOMIZATION_TEMPLATES t
    INNER JOIN dbo.PRODUCTS p ON p.CUSTOMIZATION_TEMPLATE_ID = t.CUSTOMIZATION_TEMPLATE_ID
    WHERE p.PRODUCT_ID = @PRODUCT_ID AND t.IS_ACTIVE = 1;

    SELECT DISTINCT
        g.CUSTOMIZATION_GROUP_ID AS CustomizationGroupId,
        g.GROUP_CODE AS GroupCode,
        g.GROUP_NAME_EN AS GroupNameEn,
        g.GROUP_NAME_AR AS GroupNameAr,
        g.IS_ADDITIONAL_PRICE_AVAILABLE AS IsAdditionalPriceAvailable,
        g.PRICING_TYPE AS PricingType,
        g.PRICING_VALUE AS PricingValue,
        g.IS_ACTIVE AS IsActive
    FROM dbo.CUSTOMIZATION_GROUPS g
    INNER JOIN dbo.TEMPLATE_GROUP_MAPPING m ON m.CUSTOMIZATION_GROUP_ID = g.CUSTOMIZATION_GROUP_ID
    INNER JOIN dbo.PRODUCTS p ON p.CUSTOMIZATION_TEMPLATE_ID = m.CUSTOMIZATION_TEMPLATE_ID
    WHERE p.PRODUCT_ID = @PRODUCT_ID AND g.IS_ACTIVE = 1 AND m.IS_ACTIVE = 1;

    SELECT 
        o.CUSTOMIZATION_OPTION_ID AS CustomizationOptionId,
        o.CUSTOMIZATION_GROUP_ID AS CustomizationGroupId,
        o.OPTION_CODE AS OptionCode,
        o.OPTION_NAME_EN AS OptionNameEn,
        o.OPTION_NAME_AR AS OptionNameAr,
        o.ADDITIONAL_PRICE AS AdditionalPrice,
        o.IS_ACTIVE AS IsActive
    FROM dbo.CUSTOMIZATION_OPTIONS o
    INNER JOIN dbo.TEMPLATE_GROUP_MAPPING m ON m.CUSTOMIZATION_GROUP_ID = o.CUSTOMIZATION_GROUP_ID
    INNER JOIN dbo.PRODUCTS p ON p.CUSTOMIZATION_TEMPLATE_ID = m.CUSTOMIZATION_TEMPLATE_ID
    WHERE p.PRODUCT_ID = @PRODUCT_ID AND o.IS_ACTIVE = 1 AND m.IS_ACTIVE = 1;
END;');
GO
