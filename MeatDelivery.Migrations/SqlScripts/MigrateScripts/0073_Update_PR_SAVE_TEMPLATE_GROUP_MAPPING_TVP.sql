-- Migration: 0073_Update_PR_SAVE_TEMPLATE_GROUP_MAPPING_TVP.sql
-- Description: Updates dbo.PR_SAVE_TEMPLATE_GROUP_MAPPING to accept TVP dbo.TT_CUSTOMIZATION_GROUP_IDS and mirror options SP.

IF NOT EXISTS (SELECT 1 FROM sys.types WHERE name = 'TT_CUSTOMIZATION_GROUP_IDS' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TYPE dbo.TT_CUSTOMIZATION_GROUP_IDS AS TABLE
    (
        GROUP_ID BIGINT NOT NULL
    );
END;
GO

CREATE OR ALTER PROCEDURE dbo.PR_SAVE_TEMPLATE_GROUP_MAPPING
(
    @MODE                       VARCHAR(10),
    @TEMPLATE_GROUP_MAPPING_ID  BIGINT          = NULL,
    @CUSTOMIZATION_TEMPLATE_ID  BIGINT          = NULL,
    @CUSTOMIZATION_GROUP_ID     BIGINT          = NULL,
    @GROUP_IDS                  dbo.TT_CUSTOMIZATION_GROUP_IDS READONLY,
    @IS_ACTIVE                  BIT             = 1
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @MODE = UPPER(LTRIM(RTRIM(ISNULL(@MODE, 'ADD'))));

    ----------------------------------------------------------------------------
    -- 1. ADD MODE
    ----------------------------------------------------------------------------
    IF @MODE = 'ADD'
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

        -- If TVP list is passed, bulk sync/insert mappings
        IF EXISTS (SELECT 1 FROM @GROUP_IDS)
        BEGIN
            IF EXISTS (
                SELECT 1 FROM @GROUP_IDS g
                WHERE NOT EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_GROUPS cg WHERE cg.CUSTOMIZATION_GROUP_ID = g.GROUP_ID)
            )
            BEGIN
                RAISERROR('One or more Customization Group IDs in list do not exist.', 16, 1);
                RETURN;
            END;

            BEGIN TRANSACTION;
            BEGIN TRY
                -- Delete mappings not in the new TVP list
                DELETE FROM dbo.TEMPLATE_GROUP_MAPPING
                WHERE CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID
                  AND CUSTOMIZATION_GROUP_ID NOT IN (SELECT GROUP_ID FROM @GROUP_IDS);

                -- Insert missing mappings from TVP list
                INSERT INTO dbo.TEMPLATE_GROUP_MAPPING (CUSTOMIZATION_TEMPLATE_ID, CUSTOMIZATION_GROUP_ID, IS_ACTIVE, CREATED_AT)
                SELECT DISTINCT @CUSTOMIZATION_TEMPLATE_ID, g.GROUP_ID, 1, SYSUTCDATETIME()
                FROM @GROUP_IDS g
                WHERE NOT EXISTS (
                    SELECT 1 FROM dbo.TEMPLATE_GROUP_MAPPING tgm
                    WHERE tgm.CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID
                      AND tgm.CUSTOMIZATION_GROUP_ID = g.GROUP_ID
                );

                COMMIT TRANSACTION;
            END TRY
            BEGIN CATCH
                IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                THROW;
            END CATCH;
        END
        ELSE IF @CUSTOMIZATION_GROUP_ID IS NOT NULL AND @CUSTOMIZATION_GROUP_ID > 0
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_GROUPS WHERE CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID)
            BEGIN
                RAISERROR('Customization Group not found.', 16, 1);
                RETURN;
            END;

            IF NOT EXISTS (
                SELECT 1 FROM dbo.TEMPLATE_GROUP_MAPPING 
                WHERE CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID 
                  AND CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID
            )
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
            END;
        END;

        -- Return active mapped records for template
        SELECT 
            tgm.TEMPLATE_GROUP_MAPPING_ID   AS TemplateGroupMappingId,
            tgm.CUSTOMIZATION_TEMPLATE_ID   AS CustomizationTemplateId,
            ct.TEMPLATE_NAME_EN             AS TemplateNameEn,
            ct.TEMPLATE_NAME_AR             AS TemplateNameAr,
            tgm.CUSTOMIZATION_GROUP_ID      AS CustomizationGroupId,
            cg.GROUP_CODE                   AS GroupCode,
            cg.GROUP_NAME_EN                AS GroupNameEn,
            cg.GROUP_NAME_AR                AS GroupNameAr,
            cg.IS_ADDITIONAL_PRICE_AVAILABLE AS IsAdditionalPriceAvailable,
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

    ----------------------------------------------------------------------------
    -- 2. EDIT MODE
    ----------------------------------------------------------------------------
    IF @MODE = 'EDIT'
    BEGIN
        IF @CUSTOMIZATION_TEMPLATE_ID IS NULL OR @CUSTOMIZATION_TEMPLATE_ID <= 0
        BEGIN
            RAISERROR('Valid CustomizationTemplateId is required for edit mode.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_TEMPLATES WHERE CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID)
        BEGIN
            RAISERROR('Customization Template not found.', 16, 1);
            RETURN;
        END;

        -- If TVP list is passed, replace mappings with TVP list
        IF EXISTS (SELECT 1 FROM @GROUP_IDS)
        BEGIN
            IF EXISTS (
                SELECT 1 FROM @GROUP_IDS g
                WHERE NOT EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_GROUPS cg WHERE cg.CUSTOMIZATION_GROUP_ID = g.GROUP_ID)
            )
            BEGIN
                RAISERROR('One or more Customization Group IDs in list do not exist.', 16, 1);
                RETURN;
            END;

            BEGIN TRANSACTION;
            BEGIN TRY
                -- Delete mappings not in TVP list
                DELETE FROM dbo.TEMPLATE_GROUP_MAPPING
                WHERE CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID
                  AND CUSTOMIZATION_GROUP_ID NOT IN (SELECT GROUP_ID FROM @GROUP_IDS);

                -- Insert missing mappings
                INSERT INTO dbo.TEMPLATE_GROUP_MAPPING (CUSTOMIZATION_TEMPLATE_ID, CUSTOMIZATION_GROUP_ID, IS_ACTIVE, CREATED_AT)
                SELECT DISTINCT @CUSTOMIZATION_TEMPLATE_ID, g.GROUP_ID, 1, SYSUTCDATETIME()
                FROM @GROUP_IDS g
                WHERE NOT EXISTS (
                    SELECT 1 FROM dbo.TEMPLATE_GROUP_MAPPING tgm
                    WHERE tgm.CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID
                      AND tgm.CUSTOMIZATION_GROUP_ID = g.GROUP_ID
                );

                UPDATE tgm
                SET tgm.IS_ACTIVE = 1, tgm.UPDATED_AT = SYSUTCDATETIME()
                FROM dbo.TEMPLATE_GROUP_MAPPING tgm
                WHERE tgm.CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID;

                COMMIT TRANSACTION;
            END TRY
            BEGIN CATCH
                IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                THROW;
            END CATCH;
        END
        ELSE IF @TEMPLATE_GROUP_MAPPING_ID IS NOT NULL AND @TEMPLATE_GROUP_MAPPING_ID > 0
        BEGIN
            UPDATE dbo.TEMPLATE_GROUP_MAPPING
            SET IS_ACTIVE = ISNULL(@IS_ACTIVE, IS_ACTIVE), UPDATED_AT = SYSUTCDATETIME()
            WHERE TEMPLATE_GROUP_MAPPING_ID = @TEMPLATE_GROUP_MAPPING_ID;
        END;

        -- Return updated active mapped records
        SELECT 
            tgm.TEMPLATE_GROUP_MAPPING_ID   AS TemplateGroupMappingId,
            tgm.CUSTOMIZATION_TEMPLATE_ID   AS CustomizationTemplateId,
            ct.TEMPLATE_NAME_EN             AS TemplateNameEn,
            ct.TEMPLATE_NAME_AR             AS TemplateNameAr,
            tgm.CUSTOMIZATION_GROUP_ID      AS CustomizationGroupId,
            cg.GROUP_CODE                   AS GroupCode,
            cg.GROUP_NAME_EN                AS GroupNameEn,
            cg.GROUP_NAME_AR                AS GroupNameAr,
            cg.IS_ADDITIONAL_PRICE_AVAILABLE AS IsAdditionalPriceAvailable,
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

    ----------------------------------------------------------------------------
    -- 3. DELETE MODE (HARD DELETE FROM DB)
    ----------------------------------------------------------------------------
    IF @MODE = 'DELETE'
    BEGIN
        IF @TEMPLATE_GROUP_MAPPING_ID IS NOT NULL AND @TEMPLATE_GROUP_MAPPING_ID > 0
        BEGIN
            DELETE FROM dbo.TEMPLATE_GROUP_MAPPING
            WHERE TEMPLATE_GROUP_MAPPING_ID = @TEMPLATE_GROUP_MAPPING_ID;
        END
        ELSE IF @CUSTOMIZATION_TEMPLATE_ID IS NOT NULL AND @CUSTOMIZATION_GROUP_ID IS NOT NULL
        BEGIN
            DELETE FROM dbo.TEMPLATE_GROUP_MAPPING
            WHERE CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID
              AND CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID;
        END
        ELSE IF @CUSTOMIZATION_TEMPLATE_ID IS NOT NULL AND @CUSTOMIZATION_TEMPLATE_ID > 0
        BEGIN
            DELETE FROM dbo.TEMPLATE_GROUP_MAPPING
            WHERE CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID;
        END
        ELSE
        BEGIN
            RAISERROR('TemplateGroupMappingId or CustomizationTemplateId required for delete mode.', 16, 1);
            RETURN;
        END;

        SELECT NULL AS TemplateGroupMappingId WHERE 1 = 0;
        RETURN;
    END;

    RAISERROR('Invalid Mode specified. Use ADD, EDIT, or DELETE.', 16, 1);
END;
GO
