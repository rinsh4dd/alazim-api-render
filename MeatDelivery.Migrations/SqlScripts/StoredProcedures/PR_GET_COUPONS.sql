-- =============================================================================
-- STORED PROCEDURE: dbo.PR_GET_COUPONS
-- Description: Retrieves paginated promotional coupons supporting search,
--              ID filtering (CouponId), CouponCode, and status filtering.
--              Excludes soft-deleted records.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_GET_COUPONS
    @COUPON_ID              BIGINT = NULL,
    @COUPON_CODE            VARCHAR(50) = NULL,
    @COUPON_STATUS          VARCHAR(20) = NULL,
    @SEARCH                 NVARCHAR(150) = NULL,
    @PAGE_NUMBER            INT = 1,
    @PAGE_SIZE              INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    SELECT COUNT(1) AS TotalRecords  
    FROM dbo.COUPONS c 
    WHERE c.IS_DELETED = 0
    AND (@COUPON_ID IS NULL OR c.COUPON_ID = @COUPON_ID)
    AND (@COUPON_CODE IS NULL OR c.COUPON_CODE = @COUPON_CODE)
    AND (@COUPON_STATUS IS NULL OR c.COUPON_STATUS = @COUPON_STATUS)
    AND (@SEARCH IS NULL OR c.COUPON_CODE LIKE '%' + @SEARCH + '%' OR c.COUPON_DESC LIKE '%' + @SEARCH + '%');

    SELECT  
        c.COUPON_ID AS CouponId,
        c.COUPON_CODE AS CouponCode,
        c.DISCOUNT_TYPE AS DiscountType,
        c.DISCOUNT_VALUE AS DiscountValue,
        c.MAX_DISCOUNT_AMOUNT AS MaxDiscountAmount,
        c.MINIMUM_ORDER_AMOUNT AS MinimumOrderAmount,
        c.VALID_FROM AS ValidFrom,
        c.VALID_TO AS ValidTo,
        c.USAGE_LIMIT_TOTAL AS UsageLimitTotal,
        c.USAGE_LIMIT_PER_USER AS UsageLimitPerUser,
        c.COUPON_STATUS AS CouponStatus,
        c.COUPON_DESC AS CouponDesc,
        c.CREATED_AT AS CreatedAt,
        c.UPDATED_AT AS UpdatedAt
    FROM dbo.COUPONS c
    WHERE c.IS_DELETED = 0
    AND (@COUPON_ID IS NULL OR c.COUPON_ID = @COUPON_ID)
    AND (@COUPON_CODE IS NULL OR c.COUPON_CODE = @COUPON_CODE)
    AND (@COUPON_STATUS IS NULL OR c.COUPON_STATUS = @COUPON_STATUS)
    AND (@SEARCH IS NULL OR c.COUPON_CODE LIKE '%' + @SEARCH + '%' OR c.COUPON_DESC LIKE '%' + @SEARCH + '%')
    ORDER BY c.CREATED_AT DESC, c.COUPON_ID DESC
    OFFSET (@PAGE_NUMBER - 1) * @PAGE_SIZE ROWS
    FETCH NEXT @PAGE_SIZE ROWS ONLY;
END;
GO
