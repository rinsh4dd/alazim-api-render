-- Migration Script: 0101_Update_PR_SAVE_CUSTOMIZATION_OPTION_Pricing_Value.sql
-- Description: Update PR_SAVE_CUSTOMIZATION_OPTION and PR_GET_CUSTOMIZATION_OPTIONS to use @PRICING_VALUE instead of @ADDITIONAL_PRICE.

EXEC('
CREATE OR ALTER PROCEDURE dbo.PR_SAVE_CUSTOMIZATION_OPTION
(
    @MODE                       VARCHAR(10),
    @CUSTOMIZATION_OPTION_ID    BIGINT          = NULL,
    @CUSTOMIZATION_GROUP_ID     BIGINT          = NULL,
    @OPTION_CODE                VARCHAR(50)     = NULL,
    @OPTION_NAME_EN             NVARCHAR(150)   = NULL,
    @OPTION_NAME_AR             NVARCHAR(150)   = NULL,
    @PRICING_VALUE              DECIMAL(18,2)   = 0.00,
    @IS_ACTIVE                  BIT             = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @MODE = UPPER(LTRIM(RTRIM(@MODE)));
    SET @OPTION_CODE = UPPER(LTRIM(RTRIM(@OPTION_CODE)));
    SET @OPTION_NAME_EN = LTRIM(RTRIM(@OPTION_NAME_EN));
    SET @OPTION_NAME_AR = LTRIM(RTRIM(@OPTION_NAME_AR));

    IF @MODE = ''ADD''
    BEGIN
        IF @CUSTOMIZATION_GROUP_ID IS NULL OR @CUSTOMIZATION_GROUP_ID <= 0
        BEGIN
            RAISERROR(''Valid CustomizationGroupId is required.'', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_GROUPS WHERE CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID)
        BEGIN
            RAISERROR(''Customization Group not found.'', 16, 1);
            RETURN;
        END;

        IF @OPTION_CODE IS NULL OR @OPTION_CODE = ''''
        BEGIN
            RAISERROR(''Option code is required.'', 16, 1);
            RETURN;
        END;

        IF @OPTION_NAME_EN IS NULL OR @OPTION_NAME_EN = ''''
        BEGIN
            RAISERROR(''English option name is required.'', 16, 1);
            RETURN;
        END;

        IF @OPTION_NAME_AR IS NULL OR @OPTION_NAME_AR = ''''
        BEGIN
            RAISERROR(''Arabic option name is required.'', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_OPTIONS 
                   WHERE CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID 
                     AND UPPER(OPTION_CODE) = @OPTION_CODE)
        BEGIN
            RAISERROR(''Option code already exists in this group.'', 16, 1);
            RETURN;
        END;

        INSERT INTO dbo.CUSTOMIZATION_OPTIONS
        (
            CUSTOMIZATION_GROUP_ID,
            OPTION_CODE,
            OPTION_NAME_EN,
            OPTION_NAME_AR,
            PRICING_VALUE,
            IS_ACTIVE,
            CREATED_AT,
            UPDATED_AT
        )
        VALUES
        (
            @CUSTOMIZATION_GROUP_ID,
            @OPTION_CODE,
            @OPTION_NAME_EN,
            @OPTION_NAME_AR,
            ISNULL(@PRICING_VALUE, 0.00),
            ISNULL(@IS_ACTIVE, 1),
            SYSUTCDATETIME(),
            NULL
        );

        SET @CUSTOMIZATION_OPTION_ID = SCOPE_IDENTITY();

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
        WHERE co.CUSTOMIZATION_OPTION_ID = @CUSTOMIZATION_OPTION_ID;

        RETURN;
    END;

    IF @MODE = ''EDIT''
    BEGIN
        IF @CUSTOMIZATION_OPTION_ID IS NULL OR @CUSTOMIZATION_OPTION_ID <= 0
        BEGIN
            RAISERROR(''Valid CustomizationOptionId is required for edit mode.'', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_OPTIONS WHERE CUSTOMIZATION_OPTION_ID = @CUSTOMIZATION_OPTION_ID)
        BEGIN
            RAISERROR(''Customization Option not found.'', 16, 1);
            RETURN;
        END;

        IF @OPTION_CODE IS NULL OR @OPTION_CODE = ''''
        BEGIN
            RAISERROR(''Option code is required.'', 16, 1);
            RETURN;
        END;

        IF @OPTION_NAME_EN IS NULL OR @OPTION_NAME_EN = ''''
        BEGIN
            RAISERROR(''English option name is required.'', 16, 1);
            RETURN;
        END;

        IF @OPTION_NAME_AR IS NULL OR @OPTION_NAME_AR = ''''
        BEGIN
            RAISERROR(''Arabic option name is required.'', 16, 1);
            RETURN;
        END;

        IF @CUSTOMIZATION_GROUP_ID IS NULL
        BEGIN
            SELECT @CUSTOMIZATION_GROUP_ID = CUSTOMIZATION_GROUP_ID FROM dbo.CUSTOMIZATION_OPTIONS WHERE CUSTOMIZATION_OPTION_ID = @CUSTOMIZATION_OPTION_ID;
        END;

        IF EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_OPTIONS 
                   WHERE CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID 
                     AND UPPER(OPTION_CODE) = @OPTION_CODE 
                     AND CUSTOMIZATION_OPTION_ID <> @CUSTOMIZATION_OPTION_ID)
        BEGIN
            RAISERROR(''Option code already exists in this group.'', 16, 1);
            RETURN;
        END;

        UPDATE dbo.CUSTOMIZATION_OPTIONS
        SET 
            CUSTOMIZATION_GROUP_ID  = ISNULL(@CUSTOMIZATION_GROUP_ID, CUSTOMIZATION_GROUP_ID),
            OPTION_CODE             = @OPTION_CODE,
            OPTION_NAME_EN          = @OPTION_NAME_EN,
            OPTION_NAME_AR          = @OPTION_NAME_AR,
            PRICING_VALUE           = ISNULL(@PRICING_VALUE, PRICING_VALUE),
            IS_ACTIVE               = ISNULL(@IS_ACTIVE, IS_ACTIVE),
            UPDATED_AT              = SYSUTCDATETIME()
        WHERE CUSTOMIZATION_OPTION_ID = @CUSTOMIZATION_OPTION_ID;

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
        WHERE co.CUSTOMIZATION_OPTION_ID = @CUSTOMIZATION_OPTION_ID;

        RETURN;
    END;

    IF @MODE = ''DELETE''
    BEGIN
        DELETE FROM dbo.CUSTOMIZATION_OPTIONS
        WHERE CUSTOMIZATION_OPTION_ID = @CUSTOMIZATION_OPTION_ID;

        SELECT NULL AS CustomizationOptionId WHERE 1 = 0;
        RETURN;
    END;

    RAISERROR(''Invalid Mode specified. Use ADD, EDIT, or DELETE.'', 16, 1);
END;');
GO

EXEC('
CREATE OR ALTER PROCEDURE dbo.PR_GET_CUSTOMIZATION_OPTIONS
(
    @PAGE_NUMBER              INT           = 1,
    @PAGE_SIZE                INT           = 10,
    @SEARCH                   NVARCHAR(150) = NULL,
    @CUSTOMIZATION_GROUP_ID   BIGINT        = NULL,
    @CUSTOMIZATION_OPTION_ID  BIGINT        = NULL,
    @IS_ACTIVE                BIT           = NULL
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
    FROM dbo.CUSTOMIZATION_OPTIONS co
    JOIN dbo.CUSTOMIZATION_GROUPS cg ON co.CUSTOMIZATION_GROUP_ID = cg.CUSTOMIZATION_GROUP_ID
    WHERE (@SEARCH IS NULL 
           OR co.OPTION_CODE LIKE ''%'' + @SEARCH + ''%''
           OR co.OPTION_NAME_EN LIKE ''%'' + @SEARCH + ''%''
           OR co.OPTION_NAME_AR LIKE ''%'' + @SEARCH + ''%''
           OR cg.GROUP_NAME_EN LIKE ''%'' + @SEARCH + ''%''
           OR cg.GROUP_NAME_AR LIKE ''%'' + @SEARCH + ''%'')
      AND (@CUSTOMIZATION_GROUP_ID IS NULL OR co.CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID)
      AND (@CUSTOMIZATION_OPTION_ID IS NULL OR co.CUSTOMIZATION_OPTION_ID = @CUSTOMIZATION_OPTION_ID)
      AND (@IS_ACTIVE IS NULL OR co.IS_ACTIVE = @IS_ACTIVE);

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
    WHERE (@SEARCH IS NULL 
           OR co.OPTION_CODE LIKE ''%'' + @SEARCH + ''%''
           OR co.OPTION_NAME_EN LIKE ''%'' + @SEARCH + ''%''
           OR co.OPTION_NAME_AR LIKE ''%'' + @SEARCH + ''%''
           OR cg.GROUP_NAME_EN LIKE ''%'' + @SEARCH + ''%''
           OR cg.GROUP_NAME_AR LIKE ''%'' + @SEARCH + ''%'')
      AND (@CUSTOMIZATION_GROUP_ID IS NULL OR co.CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID)
      AND (@CUSTOMIZATION_OPTION_ID IS NULL OR co.CUSTOMIZATION_OPTION_ID = @CUSTOMIZATION_OPTION_ID)
      AND (@IS_ACTIVE IS NULL OR co.IS_ACTIVE = @IS_ACTIVE)
    ORDER BY co.CUSTOMIZATION_OPTION_ID DESC
    OFFSET (@PAGE_NUMBER - 1) * @PAGE_SIZE ROWS
    FETCH NEXT @PAGE_SIZE ROWS ONLY;
END;');
GO
