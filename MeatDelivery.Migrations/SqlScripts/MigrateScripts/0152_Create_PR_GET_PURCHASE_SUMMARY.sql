-- =============================================================================
-- 0152_Create_PR_GET_PURCHASE_SUMMARY.sql
-- Aggregates purchased product quantities from placed orders.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_GET_PURCHASE_SUMMARY
(
    @PRODUCT_ID BIGINT = NULL,
    @CUSTOMER_USER_ID BIGINT = NULL,
    @FROM_DATE DATETIME2 = NULL,
    @TO_DATE DATETIME2 = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        oi.PRODUCT_ID AS ProductId,
        MAX(oi.PRODUCT_NAME_EN) AS ProductNameEn,
        MAX(oi.PRODUCT_NAME_AR) AS ProductNameAr,
        SUM(CONVERT(DECIMAL(18,3), oi.QUANTITY)) AS TotalQuantityPurchased,
        COUNT(DISTINCT o.ORDER_ID) AS OrderCount,
        COUNT(DISTINCT o.CUSTOMER_USER_ID) AS CustomerCount
    FROM dbo.ORDERS o
    INNER JOIN dbo.ORDER_ITEMS oi ON oi.ORDER_ID = o.ORDER_ID
    WHERE o.ORDER_STATUS <> 'CANCELLED'
      AND (@PRODUCT_ID IS NULL OR oi.PRODUCT_ID = @PRODUCT_ID)
      AND (@CUSTOMER_USER_ID IS NULL OR o.CUSTOMER_USER_ID = @CUSTOMER_USER_ID)
      AND (@FROM_DATE IS NULL OR o.CREATED_AT >= @FROM_DATE)
      AND (@TO_DATE IS NULL OR o.CREATED_AT < @TO_DATE)
    GROUP BY oi.PRODUCT_ID
    ORDER BY TotalQuantityPurchased DESC, oi.PRODUCT_ID;
END;
GO
