CREATE OR ALTER PROCEDURE dbo.PR_GET_ACTIVE_BANNERS
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NOW DATETIME2 = SYSUTCDATETIME();

    SELECT  
        b.BANNER_ID AS BannerId,
        b.TITLE_EN AS TitleEn,
        b.TITLE_AR AS TitleAr,
        b.ALT_TEXT_EN AS AltTextEn,
        b.ALT_TEXT_AR AS AltTextAr,
        b.IMAGE_URL AS ImageUrl,
        b.LINK_TYPE AS LinkType,
        b.PRODUCT_ID AS ProductId,
        p.PRODUCT_NAME_EN AS ProductNameEn,
        b.CATEGORY_ID AS CategoryId,
        c.CATEGORY_NAME_EN AS CategoryNameEn,
        b.OFFER_ID AS OfferId,
        b.EXTERNAL_URL AS ExternalUrl,
        b.START_AT AS StartAt,
        b.END_AT AS EndAt
    FROM dbo.BANNERS b
    LEFT JOIN dbo.PRODUCTS p ON b.PRODUCT_ID = p.PRODUCT_ID AND p.IS_DELETED = 0 AND p.IS_ACTIVE = 1
    LEFT JOIN dbo.CATEGORIES c ON b.CATEGORY_ID = c.CATEGORY_ID AND c.IS_ACTIVE = 1
    WHERE b.IS_DELETED = 0
      AND b.IS_ACTIVE = 1
      AND @NOW >= b.START_AT
      AND @NOW <= b.END_AT
    ORDER BY b.CREATED_AT DESC, b.BANNER_ID DESC;
END;
GO
