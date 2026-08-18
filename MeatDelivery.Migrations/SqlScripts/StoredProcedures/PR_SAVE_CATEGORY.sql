-- =============================================================================
-- STORED PROCEDURE: dbo.PR_SAVE_CATEGORY
-- Description: Unified CUD procedure for categories (ADD, EDIT, DELETE modes).
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_SAVE_CATEGORY
    @MODE                 VARCHAR(10),
    @CATEGORY_ID          BIGINT = NULL,
    @CATEGORY_CODE        VARCHAR(50) = NULL,
    @CATEGORY_NAME_EN     VARCHAR(150) = NULL,
    @CATEGORY_NAME_AR     NVARCHAR(150) = NULL,
    @DESCRIPTION_EN       VARCHAR(500) = NULL,
    @DESCRIPTION_AR       NVARCHAR(500) = NULL,
    @IMAGE_URL            VARCHAR(500) = NULL,
    @DISPLAY_ORDER        INT = NULL,
    @IS_ACTIVE            BIT = NULL,
    @IS_VISIBLE           BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- =========================================================================
    -- MODE: ADD
    -- =========================================================================
    IF @MODE = 'ADD'
    BEGIN
        INSERT INTO dbo.CATEGORIES
        (
            CATEGORY_CODE,
            CATEGORY_NAME_EN,
            CATEGORY_NAME_AR,
            DESCRIPTION_EN,
            DESCRIPTION_AR,
            IMAGE_URL,
            DISPLAY_ORDER,
            IS_ACTIVE,
            IS_VISIBLE,
            CREATED_AT
        )
        VALUES
        (
            @CATEGORY_CODE,
            @CATEGORY_NAME_EN,
            @CATEGORY_NAME_AR,
            @DESCRIPTION_EN,
            @DESCRIPTION_AR,
            @IMAGE_URL,
            ISNULL(@DISPLAY_ORDER, 0),
            ISNULL(@IS_ACTIVE, 1),
            ISNULL(@IS_VISIBLE, 1),
            SYSUTCDATETIME()
        );

        SET @CATEGORY_ID = CAST(SCOPE_IDENTITY() AS BIGINT);

        SELECT
            CATEGORY_ID        AS CategoryId,
            CATEGORY_CODE      AS CategoryCode,
            CATEGORY_NAME_EN   AS CategoryNameEn,
            CATEGORY_NAME_AR   AS CategoryNameAr,
            DESCRIPTION_EN     AS DescriptionEn,
            DESCRIPTION_AR     AS DescriptionAr,
            IMAGE_URL          AS ImageUrl,
            DISPLAY_ORDER      AS DisplayOrder,
            IS_ACTIVE          AS IsActive,
            IS_VISIBLE         AS IsVisible,
            CREATED_AT         AS CreatedAt,
            UPDATED_AT         AS UpdatedAt
        FROM dbo.CATEGORIES
        WHERE CATEGORY_ID = @CATEGORY_ID;

        RETURN;
    END;

    -- =========================================================================
    -- MODE: EDIT
    -- =========================================================================
    IF @MODE = 'EDIT'
    BEGIN
        UPDATE dbo.CATEGORIES
        SET
            CATEGORY_CODE = ISNULL(@CATEGORY_CODE, CATEGORY_CODE),
            CATEGORY_NAME_EN = ISNULL(@CATEGORY_NAME_EN, CATEGORY_NAME_EN),
            CATEGORY_NAME_AR = ISNULL(@CATEGORY_NAME_AR, CATEGORY_NAME_AR),
            DESCRIPTION_EN = ISNULL(@DESCRIPTION_EN, DESCRIPTION_EN),
            DESCRIPTION_AR = ISNULL(@DESCRIPTION_AR, DESCRIPTION_AR),
            IMAGE_URL = ISNULL(@IMAGE_URL, IMAGE_URL),
            DISPLAY_ORDER = ISNULL(@DISPLAY_ORDER, DISPLAY_ORDER),
            IS_ACTIVE = ISNULL(@IS_ACTIVE, IS_ACTIVE),
            IS_VISIBLE = ISNULL(@IS_VISIBLE, IS_VISIBLE),
            UPDATED_AT = SYSUTCDATETIME()
        WHERE CATEGORY_ID = @CATEGORY_ID;

        SELECT
            CATEGORY_ID        AS CategoryId,
            CATEGORY_CODE      AS CategoryCode,
            CATEGORY_NAME_EN   AS CategoryNameEn,
            CATEGORY_NAME_AR   AS CategoryNameAr,
            DESCRIPTION_EN     AS DescriptionEn,
            DESCRIPTION_AR     AS DescriptionAr,
            IMAGE_URL          AS ImageUrl,
            DISPLAY_ORDER      AS DisplayOrder,
            IS_ACTIVE          AS IsActive,
            IS_VISIBLE         AS IsVisible,
            CREATED_AT         AS CreatedAt,
            UPDATED_AT         AS UpdatedAt
        FROM dbo.CATEGORIES
        WHERE CATEGORY_ID = @CATEGORY_ID;

        RETURN;
    END;

    -- =========================================================================
    -- MODE: DELETE
    -- =========================================================================
    IF @MODE = 'DELETE'
    BEGIN
        DELETE FROM dbo.CATEGORIES
        WHERE CATEGORY_ID = @CATEGORY_ID;

        SELECT @CATEGORY_ID AS CategoryId;

        RETURN;
    END;
END;
GO