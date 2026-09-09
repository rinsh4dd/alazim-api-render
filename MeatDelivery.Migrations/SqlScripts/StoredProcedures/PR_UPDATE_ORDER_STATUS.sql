-- =============================================================================
-- STORED PROCEDURE: dbo.PR_UPDATE_ORDER_STATUS
-- Description: Updates the status of an order and logs a new milestone event
-- into dbo.ORDER_STATUS_HISTORY.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_UPDATE_ORDER_STATUS
(
    @ORDER_ID                   BIGINT,
    @ORDER_STATUS               VARCHAR(30),
    @REMARKS                    NVARCHAR(500)   = NULL,
    @CHANGED_BY_ADMIN_USER_ID   BIGINT          = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- 1. Validate OrderId
    IF @ORDER_ID IS NULL OR @ORDER_ID <= 0
    BEGIN
        RAISERROR('Valid OrderId is required.', 16, 1);
        RETURN;
    END;

    -- 2. Validate OrderStatus
    IF @ORDER_STATUS IS NULL OR LTRIM(RTRIM(@ORDER_STATUS)) = ''
    BEGIN
        RAISERROR('Valid OrderStatus is required.', 16, 1);
        RETURN;
    END;

    SET @ORDER_STATUS = UPPER(LTRIM(RTRIM(@ORDER_STATUS)));

    IF @ORDER_STATUS NOT IN ('PLACED', 'CONFIRMED', 'PROCESSING', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED')
    BEGIN
        RAISERROR('Invalid OrderStatus provided.', 16, 1);
        RETURN;
    END;

    -- 3. Fetch Order Document Number
    DECLARE @DOC_NO VARCHAR(50);
    SELECT TOP 1 @DOC_NO = DOC_NO
    FROM dbo.ORDERS
    WHERE ORDER_ID = @ORDER_ID;

    IF @DOC_NO IS NULL
    BEGIN
        RAISERROR('Order not found.', 16, 1);
        RETURN;
    END;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- 4. Update Main Order Status
        UPDATE dbo.ORDERS
        SET ORDER_STATUS = @ORDER_STATUS,
            UPDATED_AT = SYSUTCDATETIME()
        WHERE ORDER_ID = @ORDER_ID;

        -- 5. Insert New Tracking Milestone Log into ORDER_STATUS_HISTORY
        INSERT INTO dbo.ORDER_STATUS_HISTORY
        (
            ORDER_ID,
            DOC_NO,
            ORDER_STATUS,
            REMARKS,
            CHANGED_BY_ADMIN_USER_ID,
            CREATED_AT
        )
        VALUES
        (
            @ORDER_ID,
            @DOC_NO,
            @ORDER_STATUS,
            ISNULL(NULLIF(LTRIM(RTRIM(@REMARKS)), ''), 'Order status updated to ' + @ORDER_STATUS),
            @CHANGED_BY_ADMIN_USER_ID,
            SYSUTCDATETIME()
        );

        COMMIT TRANSACTION;

        -- Return Updated Status Snapshot
        SELECT 
            @ORDER_ID AS OrderId,
            @DOC_NO AS DocNo,
            @ORDER_STATUS AS OrderStatus;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ERRMSG NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ERRMSG, 16, 1);
        RETURN;
    END CATCH;
END;
GO
