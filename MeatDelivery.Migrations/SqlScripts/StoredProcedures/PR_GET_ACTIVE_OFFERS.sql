CREATE OR ALTER PROCEDURE dbo.PR_GET_ACTIVE_OFFERS
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NOW DATETIME2 = SYSUTCDATETIME();

    -- Result Set 1: Active Offers Header
    SELECT 
        o.OFFER_ID AS OfferId,
        o.OFFER_TITLE_EN AS OfferTitleEn,
        o.OFFER_TITLE_AR AS OfferTitleAr,
        o.DISCOUNT_TYPE AS DiscountType,
        o.DISCOUNT_VALUE AS DiscountValue,
        o.MINIMUM_ORDER_AMOUNT AS MinimumOrderAmount,
        o.MAX_DISCOUNT_AMOUNT AS MaxDiscountAmount,
        o.START_AT AS StartAt,
        o.END_AT AS EndAt,
        o.IS_ACTIVE AS IsActive
    FROM dbo.OFFERS o
    WHERE o.IS_DELETED = 0
      AND o.IS_ACTIVE = 1
      AND @NOW BETWEEN o.START_AT AND o.END_AT
    ORDER BY o.CREATED_AT DESC;

    -- Result Set 2: Associated Active Scopes
    SELECT 
        s.SCOPE_ID AS ScopeId,
        s.OFFER_ID AS OfferId,
        s.SCOPE_TYPE AS ScopeType,
        s.CATEGORY_ID AS CategoryId,
        c.CATEGORY_NAME_EN AS CategoryNameEn,
        s.PRODUCT_ID AS ProductId,
        p.PRODUCT_NAME_EN AS ProductNameEn
    FROM dbo.OFFER_SCOPES s
    INNER JOIN dbo.OFFERS o ON s.OFFER_ID = o.OFFER_ID
    LEFT JOIN dbo.CATEGORIES c ON s.CATEGORY_ID = c.CATEGORY_ID
    LEFT JOIN dbo.PRODUCTS p ON s.PRODUCT_ID = p.PRODUCT_ID
    WHERE o.IS_DELETED = 0
      AND o.IS_ACTIVE = 1
      AND @NOW BETWEEN o.START_AT AND o.END_AT;
END;
GO
