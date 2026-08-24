-- =============================================================================
-- STORED PROCEDURE: dbo.PR_SAVE_CUSTOMIZATION_TEMPLATE
-- Description: Unified CUD procedure for Customization Templates (ADD, EDIT, DELETE modes).
--              Allocates DOC_NO via PR_GET_NEXT_DOC_NO on ADD mode (DOCTYPE = 'CTP1').
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_SAVE_CUSTOMIZATION_TEMPLATE
(
    @MODE                       VARCHAR(10),
    @CUSTOMIZATION_TEMPLATE_ID  BIGINT        = NULL,
    @TEMPLATE_NAME_EN           NVARCHAR(150) = NULL,
    @TEMPLATE_NAME_AR           NVARCHAR(150) = NULL,
    @DESCRIPTION_EN             NVARCHAR(500) = NULL,
    @DESCRIPTION_AR             NVARCHAR(500) = NULL,
    @IS_ACTIVE                  BIT           = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @OP_MODE VARCHAR(10) = UPPER(LTRIM(RTRIM(@MODE)));

    BEGIN TRY
        -- =========================================================================
        -- MODE: ADD
        -- =========================================================================
        IF @OP_MODE = 'ADD'
        BEGIN
            IF @TEMPLATE_NAME_EN IS NULL OR LTRIM(RTRIM(@TEMPLATE_NAME_EN)) = ''
            BEGIN
                THROW 50002, 'English template name is required.', 1;
            END;

            IF @TEMPLATE_NAME_AR IS NULL OR LTRIM(RTRIM(@TEMPLATE_NAME_AR)) = ''
            BEGIN
                THROW 50003, 'Arabic template name is required.', 1;
            END;

            SET @TEMPLATE_NAME_EN = LTRIM(RTRIM(@TEMPLATE_NAME_EN));
            SET @TEMPLATE_NAME_AR = LTRIM(RTRIM(@TEMPLATE_NAME_AR));

            DECLARE @AllocatedDocNo VARCHAR(50) = NULL;

            -- Auto-generate document number using PR_GET_NEXT_DOC_NO for DOCTYPE = 'CTP1'
            EXEC dbo.PR_GET_NEXT_DOC_NO
                @DOCTYPE = 'CTP1',
                @DOC_NO = @AllocatedDocNo OUTPUT;

            INSERT INTO dbo.CUSTOMIZATION_TEMPLATES
            (
                DOC_NO,
                DOC_TYPE,
                TEMPLATE_NAME_EN,
                TEMPLATE_NAME_AR,
                DESCRIPTION_EN,
                DESCRIPTION_AR,
                IS_ACTIVE,
                CREATED_AT
            )
            VALUES
            (
                @AllocatedDocNo,
                'CTP1',
                @TEMPLATE_NAME_EN,
                @TEMPLATE_NAME_AR,
                @DESCRIPTION_EN,
                @DESCRIPTION_AR,
                ISNULL(@IS_ACTIVE, 1),
                SYSUTCDATETIME()
            );

            SET @CUSTOMIZATION_TEMPLATE_ID = CAST(SCOPE_IDENTITY() AS BIGINT);

            SELECT
                CUSTOMIZATION_TEMPLATE_ID   AS CustomizationTemplateId,
                DOC_NO                      AS DocNo,
                DOC_TYPE                    AS DocType,
                TEMPLATE_NAME_EN            AS TemplateNameEn,
                TEMPLATE_NAME_AR            AS TemplateNameAr,
                DESCRIPTION_EN              AS DescriptionEn,
                DESCRIPTION_AR              AS DescriptionAr,
                IS_ACTIVE                   AS IsActive,
                CREATED_AT                  AS CreatedAt,
                UPDATED_AT                  AS UpdatedAt
            FROM dbo.CUSTOMIZATION_TEMPLATES
            WHERE CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID;

            RETURN;
        END;

        -- =========================================================================
        -- MODE: EDIT
        -- =========================================================================
        IF @OP_MODE = 'EDIT'
        BEGIN
            IF @CUSTOMIZATION_TEMPLATE_ID IS NULL OR @CUSTOMIZATION_TEMPLATE_ID <= 0
            BEGIN
                THROW 50005, 'CustomizationTemplateId is required for EDIT mode.', 1;
            END;

            IF NOT EXISTS
            (
                SELECT 1
                FROM dbo.CUSTOMIZATION_TEMPLATES
                WHERE CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID
            )
            BEGIN
                THROW 50006, 'Customization template not found.', 1;
            END;

            IF @TEMPLATE_NAME_EN IS NOT NULL
            BEGIN
                SET @TEMPLATE_NAME_EN = LTRIM(RTRIM(@TEMPLATE_NAME_EN));
            END;

            IF @TEMPLATE_NAME_AR IS NOT NULL
            BEGIN
                SET @TEMPLATE_NAME_AR = LTRIM(RTRIM(@TEMPLATE_NAME_AR));
            END;

            UPDATE dbo.CUSTOMIZATION_TEMPLATES
            SET
                TEMPLATE_NAME_EN = CASE
                                        WHEN @TEMPLATE_NAME_EN IS NOT NULL AND @TEMPLATE_NAME_EN <> '' THEN @TEMPLATE_NAME_EN
                                        ELSE TEMPLATE_NAME_EN
                                    END,
                TEMPLATE_NAME_AR = CASE
                                        WHEN @TEMPLATE_NAME_AR IS NOT NULL AND @TEMPLATE_NAME_AR <> '' THEN @TEMPLATE_NAME_AR
                                        ELSE TEMPLATE_NAME_AR
                                    END,
                DESCRIPTION_EN = ISNULL(@DESCRIPTION_EN, DESCRIPTION_EN),
                DESCRIPTION_AR = ISNULL(@DESCRIPTION_AR, DESCRIPTION_AR),
                IS_ACTIVE = ISNULL(@IS_ACTIVE, IS_ACTIVE),
                UPDATED_AT = SYSUTCDATETIME()
            WHERE CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID;

            SELECT
                CUSTOMIZATION_TEMPLATE_ID   AS CustomizationTemplateId,
                DOC_NO                      AS DocNo,
                DOC_TYPE                    AS DocType,
                TEMPLATE_NAME_EN            AS TemplateNameEn,
                TEMPLATE_NAME_AR            AS TemplateNameAr,
                DESCRIPTION_EN              AS DescriptionEn,
                DESCRIPTION_AR              AS DescriptionAr,
                IS_ACTIVE                   AS IsActive,
                CREATED_AT                  AS CreatedAt,
                UPDATED_AT                  AS UpdatedAt
            FROM dbo.CUSTOMIZATION_TEMPLATES
            WHERE CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID;

            RETURN;
        END;

        -- =========================================================================
        -- MODE: DELETE
        -- =========================================================================
        IF @OP_MODE = 'DELETE'
        BEGIN
            IF @CUSTOMIZATION_TEMPLATE_ID IS NULL OR @CUSTOMIZATION_TEMPLATE_ID <= 0
            BEGIN
                THROW 50008, 'CustomizationTemplateId is required for DELETE mode.', 1;
            END;

            IF NOT EXISTS
            (
                SELECT 1
                FROM dbo.CUSTOMIZATION_TEMPLATES
                WHERE CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID
            )
            BEGIN
                THROW 50009, 'Customization template not found.', 1;
            END;

            IF EXISTS
            (
                SELECT 1
                FROM dbo.PRODUCTS
                WHERE CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID
                  AND (IS_DELETED = 0 OR IS_DELETED IS NULL)
            )
            BEGIN
                THROW 50010, 'Cannot delete customization template because active products are assigned to it.', 1;
            END;

            DELETE FROM dbo.CUSTOMIZATION_TEMPLATES
            WHERE CUSTOMIZATION_TEMPLATE_ID = @CUSTOMIZATION_TEMPLATE_ID;

            SELECT
                @CUSTOMIZATION_TEMPLATE_ID AS CustomizationTemplateId;

            RETURN;
        END;

        THROW 50011, 'Invalid mode specified. Valid modes are ADD, EDIT, DELETE.', 1;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
