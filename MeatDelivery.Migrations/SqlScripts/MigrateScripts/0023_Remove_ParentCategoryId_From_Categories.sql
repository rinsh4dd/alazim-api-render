-- =============================================================================
-- Migration: 0023_Remove_ParentCategoryId_From_Categories.sql
-- Description: Removes PARENT_CATEGORY_ID column from dbo.CATEGORIES
--              and updates PR_SAVE_CATEGORY and PR_GET_CATEGORIES procedures.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. DROP FK, INDEX, AND COLUMN FROM dbo.CATEGORIES
-- -----------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_CATEGORIES_PARENT')
BEGIN
    ALTER TABLE dbo.CATEGORIES DROP CONSTRAINT FK_CATEGORIES_PARENT;
END;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CATEGORIES_PARENT' AND object_id = OBJECT_ID('dbo.CATEGORIES'))
BEGIN
    DROP INDEX IX_CATEGORIES_PARENT ON dbo.CATEGORIES;
END;
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.CATEGORIES') AND name = 'PARENT_CATEGORY_ID')
BEGIN
    ALTER TABLE dbo.CATEGORIES DROP COLUMN PARENT_CATEGORY_ID;
END;
GO

-- -----------------------------------------------------------------------------
-- 2. UPDATE PR_SAVE_CATEGORY
-- -----------------------------------------------------------------------------
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

    IF @MODE = 'ADD'
    BEGIN
        INSERT INTO dbo.CATEGORIES
        (
            CATEGORY_CODE, CATEGORY_NAME_EN, CATEGORY_NAME_AR,
            DESCRIPTION_EN, DESCRIPTION_AR, IMAGE_URL,
            DISPLAY_ORDER, IS_ACTIVE, IS_VISIBLE, CREATED_AT
        )
        VALUES
        (
            @CATEGORY_CODE, @CATEGORY_NAME_EN, @CATEGORY_NAME_AR,
            @DESCRIPTION_EN, @DESCRIPTION_AR, @IMAGE_URL,
            ISNULL(@DISPLAY_ORDER, 0), ISNULL(@IS_ACTIVE, 1), ISNULL(@IS_VISIBLE, 1), SYSUTCDATETIME()
        );

        SET @CATEGORY_ID = CAST(SCOPE_IDENTITY() AS BIGINT);

        SELECT
            CATEGORY_ID AS CategoryId, CATEGORY_CODE AS CategoryCode,
            CATEGORY_NAME_EN AS CategoryNameEn, CATEGORY_NAME_AR AS CategoryNameAr,
            DESCRIPTION_EN AS DescriptionEn, DESCRIPTION_AR AS DescriptionAr,
            IMAGE_URL AS ImageUrl, DISPLAY_ORDER AS DisplayOrder,
            IS_ACTIVE AS IsActive, IS_VISIBLE AS IsVisible,
            CREATED_AT AS CreatedAt, UPDATED_AT AS UpdatedAt
        FROM dbo.CATEGORIES
        WHERE CATEGORY_ID = @CATEGORY_ID;

        RETURN;
    END;

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
            CATEGORY_ID AS CategoryId, CATEGORY_CODE AS CategoryCode,
            CATEGORY_NAME_EN AS CategoryNameEn, CATEGORY_NAME_AR AS CategoryNameAr,
            DESCRIPTION_EN AS DescriptionEn, DESCRIPTION_AR AS DescriptionAr,
            IMAGE_URL AS ImageUrl, DISPLAY_ORDER AS DisplayOrder,
            IS_ACTIVE AS IsActive, IS_VISIBLE AS IsVisible,
            CREATED_AT AS CreatedAt, UPDATED_AT AS UpdatedAt
        FROM dbo.CATEGORIES
        WHERE CATEGORY_ID = @CATEGORY_ID;

        RETURN;
    END;

    IF @MODE = 'DELETE'
    BEGIN
        DELETE FROM dbo.CATEGORIES WHERE CATEGORY_ID = @CATEGORY_ID;
        SELECT @CATEGORY_ID AS CategoryId;
        RETURN;
    END;
END;
GO

-- -----------------------------------------------------------------------------
-- 3. UPDATE PR_GET_CATEGORIES
-- -----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.PR_GET_CATEGORIES
    @PAGE_NUMBER            INT = 1,
    @PAGE_SIZE              INT = 10,
    @SEARCH_TERM            NVARCHAR(150) = NULL,
    @CATEGORY_ID            BIGINT = NULL,
    @IS_ACTIVE              BIT = NULL,
    @IS_VISIBLE             BIT = NULL,
    @SORT_BY                VARCHAR(50) = 'DisplayOrder',
    @SORT_ORDER             VARCHAR(10) = 'ASC'
AS
BEGIN
    SET NOCOUNT ON;

    IF @PAGE_NUMBER IS NULL OR @PAGE_NUMBER < 1 SET @PAGE_NUMBER = 1;
    IF @PAGE_SIZE IS NULL OR @PAGE_SIZE < 1 SET @PAGE_SIZE = 10;
    IF @PAGE_SIZE > 100 SET @PAGE_SIZE = 100;

    SET @SEARCH_TERM = LTRIM(RTRIM(@SEARCH_TERM));
    IF @SEARCH_TERM = '' SET @SEARCH_TERM = NULL;

    SELECT COUNT(1) AS TotalRecords
    FROM dbo.CATEGORIES c
    WHERE (@SEARCH_TERM IS NULL OR c.CATEGORY_NAME_EN LIKE '%' + @SEARCH_TERM + '%' OR c.CATEGORY_NAME_AR LIKE '%' + @SEARCH_TERM + '%' OR c.CATEGORY_CODE LIKE '%' + @SEARCH_TERM + '%')
      AND (@CATEGORY_ID IS NULL OR c.CATEGORY_ID = @CATEGORY_ID)
      AND (@IS_ACTIVE IS NULL OR c.IS_ACTIVE = @IS_ACTIVE)
      AND (@IS_VISIBLE IS NULL OR c.IS_VISIBLE = @IS_VISIBLE);

    SELECT 
        c.CATEGORY_ID AS CategoryId,
        c.CATEGORY_CODE AS CategoryCode,
        c.CATEGORY_NAME_EN AS CategoryNameEn,
        c.CATEGORY_NAME_AR AS CategoryNameAr,
        c.DESCRIPTION_EN AS DescriptionEn,
        c.DESCRIPTION_AR AS DescriptionAr,
        c.IMAGE_URL AS ImageUrl,
        c.DISPLAY_ORDER AS DisplayOrder,
        c.IS_ACTIVE AS IsActive,
        c.IS_VISIBLE AS IsVisible,
        c.CREATED_AT AS CreatedAt,
        c.UPDATED_AT AS UpdatedAt
    FROM dbo.CATEGORIES c
    WHERE (@SEARCH_TERM IS NULL OR c.CATEGORY_NAME_EN LIKE '%' + @SEARCH_TERM + '%' OR c.CATEGORY_NAME_AR LIKE '%' + @SEARCH_TERM + '%' OR c.CATEGORY_CODE LIKE '%' + @SEARCH_TERM + '%')
      AND (@CATEGORY_ID IS NULL OR c.CATEGORY_ID = @CATEGORY_ID)
      AND (@IS_ACTIVE IS NULL OR c.IS_ACTIVE = @IS_ACTIVE)
      AND (@IS_VISIBLE IS NULL OR c.IS_VISIBLE = @IS_VISIBLE)
    ORDER BY
        CASE WHEN @SORT_BY = 'DisplayOrder' AND UPPER(@SORT_ORDER) = 'ASC' THEN c.DISPLAY_ORDER END ASC,
        CASE WHEN @SORT_BY = 'DisplayOrder' AND UPPER(@SORT_ORDER) = 'DESC' THEN c.DISPLAY_ORDER END DESC,
        CASE WHEN @SORT_BY = 'CategoryNameEn' AND UPPER(@SORT_ORDER) = 'ASC' THEN c.CATEGORY_NAME_EN END ASC,
        CASE WHEN @SORT_BY = 'CategoryNameEn' AND UPPER(@SORT_ORDER) = 'DESC' THEN c.CATEGORY_NAME_EN END DESC,
        CASE WHEN @SORT_BY = 'CategoryNameAr' AND UPPER(@SORT_ORDER) = 'ASC' THEN c.CATEGORY_NAME_AR END ASC,
        CASE WHEN @SORT_BY = 'CategoryNameAr' AND UPPER(@SORT_ORDER) = 'DESC' THEN c.CATEGORY_NAME_AR END DESC,
        CASE WHEN @SORT_BY = 'CreatedAt' AND UPPER(@SORT_ORDER) = 'ASC' THEN c.CREATED_AT END ASC,
        CASE WHEN @SORT_BY = 'CreatedAt' AND UPPER(@SORT_ORDER) = 'DESC' THEN c.CREATED_AT END DESC,
        c.CATEGORY_ID DESC
    OFFSET (@PAGE_NUMBER - 1) * @PAGE_SIZE ROWS
    FETCH NEXT @PAGE_SIZE ROWS ONLY;
END;
GO
