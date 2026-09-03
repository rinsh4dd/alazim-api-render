-- Migration Script: 0099_Drop_Pricing_Value_From_Customization_Groups.sql
-- Description: Drop unused PRICING_VALUE column from dbo.CUSTOMIZATION_GROUPS table and update related stored procedures.

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.CUSTOMIZATION_GROUPS') AND name = 'PRICING_VALUE')
BEGIN
    -- 1. Drop any DEFAULT constraints bound to PRICING_VALUE column
    DECLARE @ConstraintName NVARCHAR(200);
    SELECT @ConstraintName = name
    FROM sys.default_constraints
    WHERE parent_object_id = OBJECT_ID(N'dbo.CUSTOMIZATION_GROUPS')
      AND parent_column_id = COLUMNPROPERTY(OBJECT_ID(N'dbo.CUSTOMIZATION_GROUPS'), 'PRICING_VALUE', 'ColumnId');

    IF @ConstraintName IS NOT NULL
    BEGIN
        EXEC('ALTER TABLE dbo.CUSTOMIZATION_GROUPS DROP CONSTRAINT [' + @ConstraintName + '];');
    END;

    -- 2. Drop PRICING_VALUE column
    ALTER TABLE dbo.CUSTOMIZATION_GROUPS
    DROP COLUMN PRICING_VALUE;
END;
GO

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
        cg.IS_CUSTOM_DATA_ALLOWED          AS IsCustomDataAllowed,
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
END;');
GO

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
    @IS_CUSTOM_DATA_ALLOWED          BIT           = 0,
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
            IS_CUSTOM_DATA_ALLOWED,
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
            ISNULL(@IS_CUSTOM_DATA_ALLOWED, 0),
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
            cg.IS_CUSTOM_DATA_ALLOWED          AS IsCustomDataAllowed,
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

        UPDATE dbo.CUSTOMIZATION_GROUPS
        SET 
            GROUP_CODE                    = @GROUP_CODE,
            GROUP_NAME_EN                 = @GROUP_NAME_EN,
            GROUP_NAME_AR                 = @GROUP_NAME_AR,
            IS_ADDITIONAL_PRICE_AVAILABLE = ISNULL(@IS_ADDITIONAL_PRICE_AVAILABLE, IS_ADDITIONAL_PRICE_AVAILABLE),
            PRICING_TYPE                  = ISNULL(@PRICING_TYPE, PRICING_TYPE),
            IS_CUSTOM_DATA_ALLOWED        = ISNULL(@IS_CUSTOM_DATA_ALLOWED, IS_CUSTOM_DATA_ALLOWED),
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
            cg.IS_CUSTOM_DATA_ALLOWED          AS IsCustomDataAllowed,
            cg.IS_ACTIVE                       AS IsActive,
            cg.CREATED_AT                      AS CreatedAt,
            cg.UPDATED_AT                      AS UpdatedAt
        FROM dbo.CUSTOMIZATION_GROUPS cg
        WHERE cg.CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID;

        RETURN;
    END;

    IF @MODE = ''DELETE''
    BEGIN
        DELETE FROM dbo.CUSTOMIZATION_GROUPS
        WHERE CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID;

        SELECT NULL AS CustomizationGroupId WHERE 1 = 0;
        RETURN;
    END;

    RAISERROR(''Invalid Mode specified. Use ADD, EDIT, or DELETE.'', 16, 1);
END;');
GO
