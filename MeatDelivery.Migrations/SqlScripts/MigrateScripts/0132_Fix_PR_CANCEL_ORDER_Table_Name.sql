IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[PR_CANCEL_ORDER]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[PR_CANCEL_ORDER];
GO

CREATE PROCEDURE [dbo].[PR_CANCEL_ORDER]
    @P_ORDER_ID             BIGINT,
    @P_CUSTOMER_USER_ID     BIGINT = NULL,
    @P_ADMIN_USER_ID        BIGINT = NULL,
    @P_CANCEL_REASON        NVARCHAR(255),
    @P_REMARKS              NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Validate Order Existence & Customer Ownership
    IF NOT EXISTS (SELECT 1 FROM dbo.ORDERS WHERE ORDER_ID = @P_ORDER_ID)
    BEGIN
        RAISERROR('Order not found.', 16, 1);
        RETURN;
    END

    IF @P_CUSTOMER_USER_ID IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM dbo.ORDERS WHERE ORDER_ID = @P_ORDER_ID AND CUSTOMER_USER_ID = @P_CUSTOMER_USER_ID
    )
    BEGIN
        RAISERROR('Order not found or access denied.', 16, 1);
        RETURN;
    END

    -- 2. Fetch Current Status & Enforce Cancellation Constraint
    DECLARE @V_PREVIOUS_STATUS NVARCHAR(50);
    DECLARE @V_DOC_NO NVARCHAR(50);

    SELECT 
        @V_PREVIOUS_STATUS = ORDER_STATUS,
        @V_DOC_NO = DOC_NO
    FROM dbo.ORDERS 
    WHERE ORDER_ID = @P_ORDER_ID;

    IF @V_PREVIOUS_STATUS IN ('PROCESSING', 'OUT_FOR_DELIVERY', 'DELIVERED')
    BEGIN
        RAISERROR('Order cannot be cancelled once processing has started or after delivery.', 16, 1);
        RETURN;
    END

    IF @V_PREVIOUS_STATUS = 'CANCELLED'
    BEGIN
        RAISERROR('Order is already cancelled.', 16, 1);
        RETURN;
    END

    -- 3. Perform Status Update
    UPDATE dbo.ORDERS
    SET 
        ORDER_STATUS = 'CANCELLED',
        UPDATED_AT = GETDATE()
    WHERE ORDER_ID = @P_ORDER_ID;

    -- 4. Construct Remarks & Record Status History
    DECLARE @V_FULL_REMARKS NVARCHAR(750);
    SET @V_FULL_REMARKS = CONCAT('Cancelled (', @P_CANCEL_REASON, ')', CASE WHEN @P_REMARKS IS NOT NULL AND LEN(@P_REMARKS) > 0 THEN CONCAT(' - ', @P_REMARKS) ELSE '' END);

    INSERT INTO dbo.ORDER_STATUS_HISTORY (
        ORDER_ID,
        ORDER_STATUS,
        REMARKS,
        CREATED_AT
    ) VALUES (
        @P_ORDER_ID,
        'CANCELLED',
        @V_FULL_REMARKS,
        GETDATE()
    );

    -- 5. Return Output DTO Payload
    SELECT 
        @P_ORDER_ID AS OrderId,
        @V_DOC_NO AS DocNo,
        @V_PREVIOUS_STATUS AS PreviousStatus,
        'CANCELLED' AS NewStatus,
        dbo.fn_GET_UAE_CURRENT_TIME() AS CancelledAtUae;
END
GO
