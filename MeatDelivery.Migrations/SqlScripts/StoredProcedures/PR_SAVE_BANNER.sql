CREATE OR ALTER PROCEDURE dbo.PR_SAVE_BANNER
    @MODE           VARCHAR(10),        -- 'ADD', 'EDIT', 'DELETE'
    @BANNER_ID      BIGINT = NULL,
    @TITLE_EN       NVARCHAR(150) = NULL,
    @TITLE_AR       NVARCHAR(150) = NULL,
    @ALT_TEXT_EN    NVARCHAR(250) = NULL,
    @ALT_TEXT_AR    NVARCHAR(250) = NULL,
    @IMAGE_URL      VARCHAR(500) = NULL,
    @LINK_TYPE      VARCHAR(20) = NULL, -- 'NONE', 'PRODUCT', 'CATEGORY', 'OFFER', 'EXTERNAL'
    @PRODUCT_ID     BIGINT = NULL,
    @CATEGORY_ID    BIGINT = NULL,
    @OFFER_ID       BIGINT = NULL,
    @EXTERNAL_URL   VARCHAR(500) = NULL,
    @START_AT       DATETIME2 = NULL,
    @END_AT         DATETIME2 = NULL,
    @IS_ACTIVE      BIT = 1,
    @ACTIONED_BY    BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF UPPER(@MODE) = 'ADD'
    BEGIN
        IF @IMAGE_URL IS NULL OR LTRIM(RTRIM(@IMAGE_URL)) = ''
        BEGIN
            RAISERROR('Image URL is required.', 16, 1);
            RETURN;
        END

        IF @START_AT >= @END_AT
        BEGIN
            RAISERROR('End time must be later than start time.', 16, 1);
            RETURN;
        END

        -- Nullify unrelated link fields according to LINK_TYPE
        IF UPPER(@LINK_TYPE) = 'NONE'
        BEGIN
            SET @PRODUCT_ID = NULL; SET @CATEGORY_ID = NULL; SET @OFFER_ID = NULL; SET @EXTERNAL_URL = NULL;
        END
        ELSE IF UPPER(@LINK_TYPE) = 'PRODUCT'
        BEGIN
            IF @PRODUCT_ID IS NULL
            BEGIN
                RAISERROR('Product ID is required for PRODUCT link type.', 16, 1);
                RETURN;
            END
            SET @CATEGORY_ID = NULL; SET @OFFER_ID = NULL; SET @EXTERNAL_URL = NULL;
        END
        ELSE IF UPPER(@LINK_TYPE) = 'CATEGORY'
        BEGIN
            IF @CATEGORY_ID IS NULL
            BEGIN
                RAISERROR('Category ID is required for CATEGORY link type.', 16, 1);
                RETURN;
            END
            SET @PRODUCT_ID = NULL; SET @OFFER_ID = NULL; SET @EXTERNAL_URL = NULL;
        END
        ELSE IF UPPER(@LINK_TYPE) = 'OFFER'
        BEGIN
            IF @OFFER_ID IS NULL
            BEGIN
                RAISERROR('Offer ID is required for OFFER link type.', 16, 1);
                RETURN;
            END
            SET @PRODUCT_ID = NULL; SET @CATEGORY_ID = NULL; SET @EXTERNAL_URL = NULL;
        END
        ELSE IF UPPER(@LINK_TYPE) = 'EXTERNAL'
        BEGIN
            IF @EXTERNAL_URL IS NULL OR LTRIM(RTRIM(@EXTERNAL_URL)) = ''
            BEGIN
                RAISERROR('External URL is required for EXTERNAL link type.', 16, 1);
                RETURN;
            END
            SET @PRODUCT_ID = NULL; SET @CATEGORY_ID = NULL; SET @OFFER_ID = NULL;
        END

        INSERT INTO dbo.BANNERS
        (
            TITLE_EN, TITLE_AR, ALT_TEXT_EN, ALT_TEXT_AR, IMAGE_URL, LINK_TYPE,
            PRODUCT_ID, CATEGORY_ID, OFFER_ID, EXTERNAL_URL, START_AT, END_AT,
            IS_ACTIVE, CREATED_BY, CREATED_AT, IS_DELETED
        )
        VALUES
        (
            @TITLE_EN, @TITLE_AR, @ALT_TEXT_EN, @ALT_TEXT_AR, @IMAGE_URL, UPPER(@LINK_TYPE),
            @PRODUCT_ID, @CATEGORY_ID, @OFFER_ID, @EXTERNAL_URL, @START_AT, @END_AT,
            ISNULL(@IS_ACTIVE, 1), @ACTIONED_BY, SYSUTCDATETIME(), 0
        );

        SET @BANNER_ID = SCOPE_IDENTITY();
    END
    ELSE IF UPPER(@MODE) = 'EDIT'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.BANNERS WHERE BANNER_ID = @BANNER_ID AND IS_DELETED = 0)
        BEGIN
            RAISERROR('Banner record not found.', 16, 1);
            RETURN;
        END

        IF @START_AT IS NOT NULL AND @END_AT IS NOT NULL AND @START_AT >= @END_AT
        BEGIN
            RAISERROR('End time must be later than start time.', 16, 1);
            RETURN;
        END

        UPDATE dbo.BANNERS
        SET TITLE_EN      = ISNULL(@TITLE_EN, TITLE_EN),
            TITLE_AR      = ISNULL(@TITLE_AR, TITLE_AR),
            ALT_TEXT_EN   = ISNULL(@ALT_TEXT_EN, ALT_TEXT_EN),
            ALT_TEXT_AR   = ISNULL(@ALT_TEXT_AR, ALT_TEXT_AR),
            IMAGE_URL     = ISNULL(@IMAGE_URL, IMAGE_URL),
            LINK_TYPE     = ISNULL(UPPER(@LINK_TYPE), LINK_TYPE),
            PRODUCT_ID    = @PRODUCT_ID,
            CATEGORY_ID   = @CATEGORY_ID,
            OFFER_ID      = @OFFER_ID,
            EXTERNAL_URL  = @EXTERNAL_URL,
            START_AT      = ISNULL(@START_AT, START_AT),
            END_AT        = ISNULL(@END_AT, END_AT),
            IS_ACTIVE     = ISNULL(@IS_ACTIVE, IS_ACTIVE),
            UPDATED_BY    = @ACTIONED_BY,
            UPDATED_AT    = SYSUTCDATETIME()
        WHERE BANNER_ID = @BANNER_ID AND IS_DELETED = 0;
    END
    ELSE IF UPPER(@MODE) = 'DELETE'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.BANNERS WHERE BANNER_ID = @BANNER_ID AND IS_DELETED = 0)
        BEGIN
            RAISERROR('Banner record not found or already deleted.', 16, 1);
            RETURN;
        END

        UPDATE dbo.BANNERS
        SET IS_DELETED = 1,
            DELETED_AT = SYSUTCDATETIME(),
            UPDATED_BY = @ACTIONED_BY
        WHERE BANNER_ID = @BANNER_ID;
    END
    ELSE
    BEGIN
        RAISERROR('Invalid operation mode. Supported modes: ADD, EDIT, DELETE.', 16, 1);
        RETURN;
    END

    -- Return the affected/created record
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
        b.END_AT AS EndAt,
        b.IS_ACTIVE AS IsActive,
        b.CREATED_AT AS CreatedAt,
        b.UPDATED_AT AS UpdatedAt
    FROM dbo.BANNERS b
    LEFT JOIN dbo.PRODUCTS p ON b.PRODUCT_ID = p.PRODUCT_ID
    LEFT JOIN dbo.CATEGORIES c ON b.CATEGORY_ID = c.CATEGORY_ID
    WHERE b.BANNER_ID = @BANNER_ID;
END;
GO
