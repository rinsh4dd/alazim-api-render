-- =============================================================================
-- STORED PROCEDURE: dbo.PR_SAVE_CUSTOMIZATION_OPTION
-- Description: Handles ADD, EDIT, DELETE operations for Customization Options (dbo.CUSTOMIZATION_OPTIONS).
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_SAVE_CUSTOMIZATION_OPTION
(
    @MODE                       VARCHAR(10),
    @CUSTOMIZATION_OPTION_ID    BIGINT          = NULL,
    @CUSTOMIZATION_GROUP_ID     BIGINT          = NULL,
    @OPTION_CODE                VARCHAR(50)     = NULL,
    @OPTION_NAME_EN             NVARCHAR(150)   = NULL,
    @OPTION_NAME_AR             NVARCHAR(150)   = NULL,
    @ADDITIONAL_PRICE           DECIMAL(18,2)   = 0.00,
    @IS_ACTIVE                  BIT             = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @MODE = UPPER(LTRIM(RTRIM(@MODE)));
    SET @OPTION_CODE = UPPER(LTRIM(RTRIM(@OPTION_CODE)));
    SET @OPTION_NAME_EN = LTRIM(RTRIM(@OPTION_NAME_EN));
    SET @OPTION_NAME_AR = LTRIM(RTRIM(@OPTION_NAME_AR));

    ----------------------------------------------------------------------------
    -- 1. ADD MODE
    ----------------------------------------------------------------------------
    IF @MODE = 'ADD'
    BEGIN
        IF @CUSTOMIZATION_GROUP_ID IS NULL OR @CUSTOMIZATION_GROUP_ID <= 0
        BEGIN
            RAISERROR('Valid CustomizationGroupId is required.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_GROUPS WHERE CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID)
        BEGIN
            RAISERROR('Customization Group not found.', 16, 1);
            RETURN;
        END;

        IF @OPTION_CODE IS NULL OR @OPTION_CODE = ''
        BEGIN
            RAISERROR('Option code is required.', 16, 1);
            RETURN;
        END;

        IF @OPTION_NAME_EN IS NULL OR @OPTION_NAME_EN = ''
        BEGIN
            RAISERROR('English option name is required.', 16, 1);
            RETURN;
        END;

        IF @OPTION_NAME_AR IS NULL OR @OPTION_NAME_AR = ''
        BEGIN
            RAISERROR('Arabic option name is required.', 16, 1);
            RETURN;
        END;

        -- Check duplicate OPTION_CODE per CUSTOMIZATION_GROUP_ID
        IF EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_OPTIONS 
                   WHERE CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID 
                     AND UPPER(OPTION_CODE) = @OPTION_CODE)
        BEGIN
            RAISERROR('Option code already exists in this group.', 16, 1);
            RETURN;
        END;

        INSERT INTO dbo.CUSTOMIZATION_OPTIONS
        (
            CUSTOMIZATION_GROUP_ID,
            OPTION_CODE,
            OPTION_NAME_EN,
            OPTION_NAME_AR,
            ADDITIONAL_PRICE,
            IS_ACTIVE,
            CREATED_AT,
            UPDATED_AT
        )
        VALUES
        (
            @CUSTOMIZATION_GROUP_ID,
            @OPTION_CODE,
            @OPTION_NAME_EN,
            @OPTION_NAME_AR,
            ISNULL(@ADDITIONAL_PRICE, 0.00),
            ISNULL(@IS_ACTIVE, 1),
            SYSUTCDATETIME(),
            NULL
        );

        SET @CUSTOMIZATION_OPTION_ID = SCOPE_IDENTITY();

        -- Return newly created option
        SELECT 
            co.CUSTOMIZATION_OPTION_ID   AS CustomizationOptionId,
            co.CUSTOMIZATION_GROUP_ID    AS CustomizationGroupId,
            cg.GROUP_NAME_EN             AS GroupNameEn,
            cg.GROUP_NAME_AR             AS GroupNameAr,
            co.OPTION_CODE               AS OptionCode,
            co.OPTION_NAME_EN            AS OptionNameEn,
            co.OPTION_NAME_AR            AS OptionNameAr,
            co.ADDITIONAL_PRICE          AS AdditionalPrice,
            co.IS_ACTIVE                 AS IsActive,
            co.CREATED_AT                AS CreatedAt,
            co.UPDATED_AT                AS UpdatedAt
        FROM dbo.CUSTOMIZATION_OPTIONS co
        JOIN dbo.CUSTOMIZATION_GROUPS cg ON co.CUSTOMIZATION_GROUP_ID = cg.CUSTOMIZATION_GROUP_ID
        WHERE co.CUSTOMIZATION_OPTION_ID = @CUSTOMIZATION_OPTION_ID;

        RETURN;
    END;

    ----------------------------------------------------------------------------
    -- 2. EDIT MODE
    ----------------------------------------------------------------------------
    IF @MODE = 'EDIT'
    BEGIN
        IF @CUSTOMIZATION_OPTION_ID IS NULL OR @CUSTOMIZATION_OPTION_ID <= 0
        BEGIN
            RAISERROR('Valid CustomizationOptionId is required for edit mode.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_OPTIONS WHERE CUSTOMIZATION_OPTION_ID = @CUSTOMIZATION_OPTION_ID)
        BEGIN
            RAISERROR('Customization Option not found.', 16, 1);
            RETURN;
        END;

        IF @OPTION_CODE IS NULL OR @OPTION_CODE = ''
        BEGIN
            RAISERROR('Option code is required.', 16, 1);
            RETURN;
        END;

        IF @OPTION_NAME_EN IS NULL OR @OPTION_NAME_EN = ''
        BEGIN
            RAISERROR('English option name is required.', 16, 1);
            RETURN;
        END;

        IF @OPTION_NAME_AR IS NULL OR @OPTION_NAME_AR = ''
        BEGIN
            RAISERROR('Arabic option name is required.', 16, 1);
            RETURN;
        END;

        -- Get target CUSTOMIZATION_GROUP_ID if not supplied
        IF @CUSTOMIZATION_GROUP_ID IS NULL
        BEGIN
            SELECT @CUSTOMIZATION_GROUP_ID = CUSTOMIZATION_GROUP_ID FROM dbo.CUSTOMIZATION_OPTIONS WHERE CUSTOMIZATION_OPTION_ID = @CUSTOMIZATION_OPTION_ID;
        END;

        -- Check duplicate OPTION_CODE for other option IDs in the same group
        IF EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_OPTIONS 
                   WHERE CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID 
                     AND UPPER(OPTION_CODE) = @OPTION_CODE 
                     AND CUSTOMIZATION_OPTION_ID <> @CUSTOMIZATION_OPTION_ID)
        BEGIN
            RAISERROR('Option code already exists in this group.', 16, 1);
            RETURN;
        END;

        UPDATE dbo.CUSTOMIZATION_OPTIONS
        SET 
            CUSTOMIZATION_GROUP_ID  = ISNULL(@CUSTOMIZATION_GROUP_ID, CUSTOMIZATION_GROUP_ID),
            OPTION_CODE             = @OPTION_CODE,
            OPTION_NAME_EN          = @OPTION_NAME_EN,
            OPTION_NAME_AR          = @OPTION_NAME_AR,
            ADDITIONAL_PRICE        = ISNULL(@ADDITIONAL_PRICE, ADDITIONAL_PRICE),
            IS_ACTIVE               = ISNULL(@IS_ACTIVE, IS_ACTIVE),
            UPDATED_AT              = SYSUTCDATETIME()
        WHERE CUSTOMIZATION_OPTION_ID = @CUSTOMIZATION_OPTION_ID;

        -- Return updated option
        SELECT 
            co.CUSTOMIZATION_OPTION_ID   AS CustomizationOptionId,
            co.CUSTOMIZATION_GROUP_ID    AS CustomizationGroupId,
            cg.GROUP_NAME_EN             AS GroupNameEn,
            cg.GROUP_NAME_AR             AS GroupNameAr,
            co.OPTION_CODE               AS OptionCode,
            co.OPTION_NAME_EN            AS OptionNameEn,
            co.OPTION_NAME_AR            AS OptionNameAr,
            co.ADDITIONAL_PRICE          AS AdditionalPrice,
            co.IS_ACTIVE                 AS IsActive,
            co.CREATED_AT                AS CreatedAt,
            co.UPDATED_AT                AS UpdatedAt
        FROM dbo.CUSTOMIZATION_OPTIONS co
        JOIN dbo.CUSTOMIZATION_GROUPS cg ON co.CUSTOMIZATION_GROUP_ID = cg.CUSTOMIZATION_GROUP_ID
        WHERE co.CUSTOMIZATION_OPTION_ID = @CUSTOMIZATION_OPTION_ID;

        RETURN;
    END;

    ----------------------------------------------------------------------------
    -- 3. DELETE MODE
    ----------------------------------------------------------------------------
    IF @MODE = 'DELETE'
    BEGIN
        IF @CUSTOMIZATION_OPTION_ID IS NULL OR @CUSTOMIZATION_OPTION_ID <= 0
        BEGIN
            RAISERROR('Valid CustomizationOptionId is required for delete mode.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_OPTIONS WHERE CUSTOMIZATION_OPTION_ID = @CUSTOMIZATION_OPTION_ID)
        BEGIN
            RAISERROR('Customization Option not found.', 16, 1);
            RETURN;
        END;

        DELETE FROM dbo.CUSTOMIZATION_OPTIONS
        WHERE CUSTOMIZATION_OPTION_ID = @CUSTOMIZATION_OPTION_ID;

        SELECT NULL AS CustomizationOptionId WHERE 1 = 0;
        RETURN;
    END;

    RAISERROR('Invalid Mode specified. Use ADD, EDIT, or DELETE.', 16, 1);
END;
GO
