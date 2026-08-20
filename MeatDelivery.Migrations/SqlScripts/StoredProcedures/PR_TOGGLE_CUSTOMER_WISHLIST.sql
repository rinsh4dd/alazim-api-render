-- =============================================================================
-- STORED PROCEDURE: dbo.PR_TOGGLE_CUSTOMER_WISHLIST
-- Description: Toggles product wishlist status for a customer (single select).
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_TOGGLE_CUSTOMER_WISHLIST
(
    @CUSTOMER_USER_ID   BIGINT,
    @PRODUCT_ID         BIGINT,
    @IN_WISHLIST        BIT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.CUSTOMER_USERS WHERE USER_ID = @CUSTOMER_USER_ID)
    BEGIN
        THROW 50034, 'Customer user not found.', 1;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.PRODUCTS WHERE PRODUCT_ID = @PRODUCT_ID AND IS_DELETED = 0)
    BEGIN
        THROW 50035, 'Product not found or deleted.', 1;
    END

    BEGIN TRANSACTION;

    -- Ensure wishlist header exists for customer (1 wishlist per customer)
    DECLARE @WISHLIST_ID BIGINT;
    SELECT @WISHLIST_ID = WISHLIST_ID FROM dbo.WISHLISTS WHERE CUSTOMER_USER_ID = @CUSTOMER_USER_ID;

    IF @WISHLIST_ID IS NULL
    BEGIN
        INSERT INTO dbo.WISHLISTS (CUSTOMER_USER_ID, CREATED_AT)
        VALUES (@CUSTOMER_USER_ID, SYSUTCDATETIME());
        SET @WISHLIST_ID = SCOPE_IDENTITY();
    END

    DECLARE @EXISTING_ITEM BIT = 0;
    IF EXISTS (SELECT 1 FROM dbo.WISHLIST_ITEMS WHERE WISHLIST_ID = @WISHLIST_ID AND PRODUCT_ID = @PRODUCT_ID)
    BEGIN
        SET @EXISTING_ITEM = 1;
    END

    -- Auto-toggle logic when @IN_WISHLIST is omitted or NULL
    IF @IN_WISHLIST IS NULL
    BEGIN
        IF @EXISTING_ITEM = 1
            SET @IN_WISHLIST = 0; -- Existed -> Remove from wishlist
        ELSE
            SET @IN_WISHLIST = 1; -- Absent -> Add to wishlist
    END

    IF @IN_WISHLIST = 1
    BEGIN
        IF @EXISTING_ITEM = 0
        BEGIN
            INSERT INTO dbo.WISHLIST_ITEMS (WISHLIST_ID, PRODUCT_ID, ADDED_AT)
            VALUES (@WISHLIST_ID, @PRODUCT_ID, SYSUTCDATETIME());
        END
    END
    ELSE
    BEGIN
        IF @EXISTING_ITEM = 1
        BEGIN
            DELETE FROM dbo.WISHLIST_ITEMS
            WHERE WISHLIST_ID = @WISHLIST_ID AND PRODUCT_ID = @PRODUCT_ID;
        END
    END

    UPDATE dbo.WISHLISTS
    SET UPDATED_AT = SYSUTCDATETIME()
    WHERE WISHLIST_ID = @WISHLIST_ID;

    COMMIT TRANSACTION;

    -- Ultra-fast Single Select Result
    SELECT
        @WISHLIST_ID AS WishlistId,
        @CUSTOMER_USER_ID AS CustomerUserId,
        @PRODUCT_ID AS ProductId,
        CAST(@IN_WISHLIST AS BIT) AS InWishlist,
        SYSUTCDATETIME() AS ActionTimestamp;
END;
GO
