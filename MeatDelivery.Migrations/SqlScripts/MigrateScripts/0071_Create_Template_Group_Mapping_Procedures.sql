-- Migration: 0071_Create_Template_Group_Mapping_Procedures.sql
-- Description: Creates stored procedures dbo.PR_SAVE_TEMPLATE_GROUP_MAPPING and dbo.PR_GET_TEMPLATE_GROUP_MAPPINGS.

-- 1. dbo.PR_SAVE_TEMPLATE_GROUP_MAPPING
CREATE OR ALTER PROCEDURE dbo.PR_SAVE_TEMPLATE_GROUP_MAPPING
(
    @MODE                       VARCHAR(10),
    @TEMPLATE_GROUP_MAPPING_ID  BIGINT      = NULL,
    @CUSTOMIZATION_TEMPLATE_ID  BIGINT      = NULL,
    @CUSTOMIZATION_GROUP_ID     BIGINT      = NULL,
    @GROUP_IDS_CSV              VARCHAR(MAX)= NULL,
    @IS_ACTIVE                  BIT         = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @MODE = UPPER(LTRIM(RTRIM(@MODE)));

    IF @MODE = 'BULK_MAP'
    BEGIN
        IF @CUSTOMIZATION_TEMPLATE_ID IS NULL OR @CUSTOMIZATION_TEMPLATE_ID <= 0
        BEGIN
            RAISERROR('Valid CustomizationTemplateId is required.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_TEMPLATES WHERE CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID)
        BEGIN
            RAISERROR('Customization Template not found.', 16, 1);
            RETURN;
        END;

        DECLARE @GroupTable TABLE (GroupId BIGINT PRIMARY KEY);

        IF @GROUP_IDS_CSV IS NOT NULL AND LTRIM(RTRIM(@GROUP_IDS_CSV)) <> ''
        BEGIN
            INSERT INTO @GroupTable (GroupId)
            SELECT DISTINCT CAST(value AS BIGINT)
            FROM STRING_SPLIT(@GROUP_IDS_CSV, ',')
            WHERE ISNUMERIC(value) = 1 AND CAST(value AS BIGINT) > 0;
        END;

        UPDATE dbo.TEMPLATE_GROUP_MAPPING
        SET IS_ACTIVE = 0, UPDATED_AT = SYSUTCDATETIME()
        WHERE CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID
          AND CUSTOMIZATION_GROUP_ID NOT IN (SELECT GroupId FROM @GroupTable);

        MERGE dbo.TEMPLATE_GROUP_MAPPING AS target
        USING (SELECT GroupId FROM @GroupTable) AS source
        ON (target.CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID AND target.CUSTOMIZATION_GROUP_ID = source.GroupId)
        WHEN MATCHED THEN
            UPDATE SET target.IS_ACTIVE = 1, target.UPDATED_AT = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN
            INSERT (CUSTOMIZATION_TEMPLATE_ID, CUSTOMIZATION_GROUP_ID, IS_ACTIVE, CREATED_AT)
            VALUES (@CUSTOMIZATION_TEMPLATE_ID, source.GroupId, 1, SYSUTCDATETIME());

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
        WHERE tgm.CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID AND tgm.IS_ACTIVE = 1
        ORDER BY tgm.TEMPLATE_GROUP_MAPPING_ID ASC;

        RETURN;
    END;

    IF @MODE = 'ADD'
    BEGIN
        IF @CUSTOMIZATION_TEMPLATE_ID IS NULL OR @CUSTOMIZATION_TEMPLATE_ID <= 0
        BEGIN
            RAISERROR('Valid CustomizationTemplateId is required.', 16, 1);
            RETURN;
        END;

        IF @CUSTOMIZATION_GROUP_ID IS NULL OR @CUSTOMIZATION_GROUP_ID <= 0
        BEGIN
            RAISERROR('Valid CustomizationGroupId is required.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_TEMPLATES WHERE CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID)
        BEGIN
            RAISERROR('Customization Template not found.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_GROUPS WHERE CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID)
        BEGIN
            RAISERROR('Customization Group not found.', 16, 1);
            RETURN;
        END;

        IF EXISTS (SELECT 1 FROM dbo.TEMPLATE_GROUP_MAPPING 
                   WHERE CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID 
                     AND CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID)
        BEGIN
            UPDATE dbo.TEMPLATE_GROUP_MAPPING
            SET IS_ACTIVE = ISNULL(@IS_ACTIVE, 1), UPDATED_AT = SYSUTCDATETIME()
            WHERE CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID 
              AND CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID;

            SELECT @TEMPLATE_GROUP_MAPPING_ID = TEMPLATE_GROUP_MAPPING_ID
            FROM dbo.TEMPLATE_GROUP_MAPPING
            WHERE CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID 
              AND CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.TEMPLATE_GROUP_MAPPING
            (
                CUSTOMIZATION_TEMPLATE_ID,
                CUSTOMIZATION_GROUP_ID,
                IS_ACTIVE,
                CREATED_AT
            )
            VALUES
            (
                @CUSTOMIZATION_TEMPLATE_ID,
                @CUSTOMIZATION_GROUP_ID,
                ISNULL(@IS_ACTIVE, 1),
                SYSUTCDATETIME()
            );

            SET @TEMPLATE_GROUP_MAPPING_ID = SCOPE_IDENTITY();
        END;

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
        WHERE tgm.TEMPLATE_GROUP_MAPPING_ID = @TEMPLATE_GROUP_MAPPING_ID;

        RETURN;
    END;

    IF @MODE = 'DELETE'
    BEGIN
        IF @TEMPLATE_GROUP_MAPPING_ID IS NULL OR @TEMPLATE_GROUP_MAPPING_ID <= 0
        BEGIN
            IF @CUSTOMIZATION_TEMPLATE_ID > 0 AND @CUSTOMIZATION_GROUP_ID > 0
            BEGIN
                SELECT @TEMPLATE_GROUP_MAPPING_ID = TEMPLATE_GROUP_MAPPING_ID
                FROM dbo.TEMPLATE_GROUP_MAPPING
                WHERE CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID AND CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID;
            END;
        END;

        IF @TEMPLATE_GROUP_MAPPING_ID IS NULL OR @TEMPLATE_GROUP_MAPPING_ID <= 0
        BEGIN
            RAISERROR('Valid TemplateGroupMappingId is required for delete mode.', 16, 1);
            RETURN;
        END;

        DELETE FROM dbo.TEMPLATE_GROUP_MAPPING
        WHERE TEMPLATE_GROUP_MAPPING_ID = @TEMPLATE_GROUP_MAPPING_ID;

        SELECT NULL AS TemplateGroupMappingId WHERE 1 = 0;
        RETURN;
    END;

    RAISERROR('Invalid Mode specified. Use BULK_MAP, ADD, or DELETE.', 16, 1);
END;
GO

-- 2. dbo.PR_GET_TEMPLATE_GROUP_MAPPINGS
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

    SELECT COUNT(1) AS TotalRecords
    FROM dbo.TEMPLATE_GROUP_MAPPING tgm
    JOIN dbo.CUSTOMIZATION_TEMPLATES ct ON tgm.CUSTOMIZATION_TEMPLATE_ID = ct.CUSTOMIZATION_TEMPLATE_ID
    JOIN dbo.CUSTOMIZATION_GROUPS cg ON tgm.CUSTOMIZATION_GROUP_ID = cg.CUSTOMIZATION_GROUP_ID
    WHERE (@CUSTOMIZATION_TEMPLATE_ID IS NULL OR tgm.CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID)
      AND (@CUSTOMIZATION_GROUP_ID IS NULL OR tgm.CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID)
      AND (@IS_ACTIVE IS NULL OR tgm.IS_ACTIVE = @IS_ACTIVE);

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
