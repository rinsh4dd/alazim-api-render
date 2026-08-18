-- =============================================================================
-- Migration: 0034_Fix_PR_GET_CATEGORIES_Remove_IsVisible.sql
-- Description: Re-creates stored procedure dbo.PR_GET_CATEGORIES without IS_VISIBLE,
--              PARENT_CATEGORY_ID, SORT_BY, and SORT_ORDER parameters/references.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_GET_CATEGORIES
    @PAGE_NUMBER            INT = 1,
    @PAGE_SIZE              INT = 10,
    @SEARCH_TERM            NVARCHAR(150) = NULL,
    @CATEGORY_ID            BIGINT = NULL,
    @IS_ACTIVE              BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Sanitize parameters
    IF @PAGE_NUMBER IS NULL OR @PAGE_NUMBER < 1 SET @PAGE_NUMBER = 1;
    IF @PAGE_SIZE IS NULL OR @PAGE_SIZE < 1 SET @PAGE_SIZE = 10;
    IF @PAGE_SIZE > 100 SET @PAGE_SIZE = 100;

    SET @SEARCH_TERM = LTRIM(RTRIM(@SEARCH_TERM));
    IF @SEARCH_TERM = '' SET @SEARCH_TERM = NULL;

    -- Result Set 1: Total Count
    SELECT COUNT(1) AS TotalRecords
    FROM dbo.CATEGORIES c
    WHERE (@SEARCH_TERM IS NULL OR c.CATEGORY_NAME_EN LIKE '%' + @SEARCH_TERM + '%' OR c.CATEGORY_NAME_AR LIKE '%' + @SEARCH_TERM + '%' OR c.CATEGORY_CODE LIKE '%' + @SEARCH_TERM + '%')
      AND (@CATEGORY_ID IS NULL OR c.CATEGORY_ID = @CATEGORY_ID)
      AND (@IS_ACTIVE IS NULL OR c.IS_ACTIVE = @IS_ACTIVE);

    -- Result Set 2: Paged Categories
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
        c.CREATED_AT AS CreatedAt,
        c.UPDATED_AT AS UpdatedAt
    FROM dbo.CATEGORIES c
    WHERE (@SEARCH_TERM IS NULL OR c.CATEGORY_NAME_EN LIKE '%' + @SEARCH_TERM + '%' OR c.CATEGORY_NAME_AR LIKE '%' + @SEARCH_TERM + '%' OR c.CATEGORY_CODE LIKE '%' + @SEARCH_TERM + '%')
      AND (@CATEGORY_ID IS NULL OR c.CATEGORY_ID = @CATEGORY_ID)
      AND (@IS_ACTIVE IS NULL OR c.IS_ACTIVE = @IS_ACTIVE)
    ORDER BY c.DISPLAY_ORDER ASC, c.CATEGORY_ID DESC
    OFFSET (@PAGE_NUMBER - 1) * @PAGE_SIZE ROWS
    FETCH NEXT @PAGE_SIZE ROWS ONLY;
END;
GO
