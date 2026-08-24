-- =============================================================================
-- STORED PROCEDURE: dbo.PR_SAVE_CUSTOMIZATION_GROUP
-- Description: Handles ADD, EDIT, DELETE operations for Customization Groups (dbo.CUSTOMIZATION_GROUPS).
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_SAVE_CUSTOMIZATION_GROUP
(
    @MODE                            VARCHAR(10),
    @CUSTOMIZATION_GROUP_ID          BIGINT        = NULL,
    @GROUP_CODE                      VARCHAR(50)   = NULL,
    @GROUP_NAME_EN                   NVARCHAR(150) = NULL,
    @GROUP_NAME_AR                   NVARCHAR(150) = NULL,
    @IS_ADDITIONAL_PRICE_AVAILABLE   BIT           = 0,
    @IS_ACTIVE                       BIT           = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @MODE = UPPER(LTRIM(RTRIM(@MODE)));
    SET @GROUP_CODE = UPPER(LTRIM(RTRIM(@GROUP_CODE)));
    SET @GROUP_NAME_EN = LTRIM(RTRIM(@GROUP_NAME_EN));
    SET @GROUP_NAME_AR = LTRIM(RTRIM(@GROUP_NAME_AR));

    ----------------------------------------------------------------------------
    -- 1. ADD MODE
    ----------------------------------------------------------------------------
    IF @MODE = 'ADD'
    BEGIN
        IF @GROUP_CODE IS NULL OR @GROUP_CODE = ''
        BEGIN
            RAISERROR('Group code is required.', 16, 1);
            RETURN;
        END;

        IF @GROUP_NAME_EN IS NULL OR @GROUP_NAME_EN = ''
        BEGIN
            RAISERROR('English group name is required.', 16, 1);
            RETURN;
        END;

        IF @GROUP_NAME_AR IS NULL OR @GROUP_NAME_AR = ''
        BEGIN
            RAISERROR('Arabic group name is required.', 16, 1);
            RETURN;
        END;

        -- Check duplicate GROUP_CODE
        IF EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_GROUPS WHERE UPPER(GROUP_CODE) = @GROUP_CODE)
        BEGIN
            RAISERROR('Group code already exists.', 16, 1);
            RETURN;
        END;

        INSERT INTO dbo.CUSTOMIZATION_GROUPS
        (
            GROUP_CODE,
            GROUP_NAME_EN,
            GROUP_NAME_AR,
            IS_ADDITIONAL_PRICE_AVAILABLE,
            IS_ACTIVE,
            CREATED_AT,
            UPDATED_AT
        )
        VALUES
        (
            @GROUP_CODE,
            @GROUP_NAME_EN,
            @GROUP_NAME_AR,
            ISNULL(@IS_ADDITIONAL_PRICE_AVAILABLE, 0),
            ISNULL(@IS_ACTIVE, 1),
            SYSUTCDATETIME(),
            NULL
        );

        SET @CUSTOMIZATION_GROUP_ID = SCOPE_IDENTITY();

        -- Return newly created group
        SELECT 
            cg.CUSTOMIZATION_GROUP_ID          AS CustomizationGroupId,
            cg.GROUP_CODE                      AS GroupCode,
            cg.GROUP_NAME_EN                   AS GroupNameEn,
            cg.GROUP_NAME_AR                   AS GroupNameAr,
            cg.IS_ADDITIONAL_PRICE_AVAILABLE   AS IsAdditionalPriceAvailable,
            cg.IS_ACTIVE                       AS IsActive,
            cg.CREATED_AT                      AS CreatedAt,
            cg.UPDATED_AT                      AS UpdatedAt
        FROM dbo.CUSTOMIZATION_GROUPS cg
        WHERE cg.CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID;

        RETURN;
    END;

    ----------------------------------------------------------------------------
    -- 2. EDIT MODE
    ----------------------------------------------------------------------------
    IF @MODE = 'EDIT'
    BEGIN
        IF @CUSTOMIZATION_GROUP_ID IS NULL OR @CUSTOMIZATION_GROUP_ID <= 0
        BEGIN
            RAISERROR('Valid CustomizationGroupId is required for edit mode.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_GROUPS WHERE CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID)
        BEGIN
            RAISERROR('Customization group not found.', 16, 1);
            RETURN;
        END;

        IF @GROUP_CODE IS NULL OR @GROUP_CODE = ''
        BEGIN
            RAISERROR('Group code is required.', 16, 1);
            RETURN;
        END;

        IF @GROUP_NAME_EN IS NULL OR @GROUP_NAME_EN = ''
        BEGIN
            RAISERROR('English group name is required.', 16, 1);
            RETURN;
        END;

        IF @GROUP_NAME_AR IS NULL OR @GROUP_NAME_AR = ''
        BEGIN
            RAISERROR('Arabic group name is required.', 16, 1);
            RETURN;
        END;

        -- Check duplicate GROUP_CODE for other group IDs
        IF EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_GROUPS WHERE UPPER(GROUP_CODE) = @GROUP_CODE AND CUSTOMIZATION_GROUP_ID <> @CUSTOMIZATION_GROUP_ID)
        BEGIN
            RAISERROR('Group code already exists.', 16, 1);
            RETURN;
        END;

        UPDATE dbo.CUSTOMIZATION_GROUPS
        SET 
            GROUP_CODE                    = @GROUP_CODE,
            GROUP_NAME_EN                 = @GROUP_NAME_EN,
            GROUP_NAME_AR                 = @GROUP_NAME_AR,
            IS_ADDITIONAL_PRICE_AVAILABLE = ISNULL(@IS_ADDITIONAL_PRICE_AVAILABLE, IS_ADDITIONAL_PRICE_AVAILABLE),
            IS_ACTIVE                     = ISNULL(@IS_ACTIVE, IS_ACTIVE),
            UPDATED_AT                    = SYSUTCDATETIME()
        WHERE CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID;

        -- Return updated group
        SELECT 
            cg.CUSTOMIZATION_GROUP_ID          AS CustomizationGroupId,
            cg.GROUP_CODE                      AS GroupCode,
            cg.GROUP_NAME_EN                   AS GroupNameEn,
            cg.GROUP_NAME_AR                   AS GroupNameAr,
            cg.IS_ADDITIONAL_PRICE_AVAILABLE   AS IsAdditionalPriceAvailable,
            cg.IS_ACTIVE                       AS IsActive,
            cg.CREATED_AT                      AS CreatedAt,
            cg.UPDATED_AT                      AS UpdatedAt
        FROM dbo.CUSTOMIZATION_GROUPS cg
        WHERE cg.CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID;

        RETURN;
    END;

    ----------------------------------------------------------------------------
    -- 3. DELETE MODE
    ----------------------------------------------------------------------------
    IF @MODE = 'DELETE'
    BEGIN
        IF @CUSTOMIZATION_GROUP_ID IS NULL OR @CUSTOMIZATION_GROUP_ID <= 0
        BEGIN
            RAISERROR('Valid CustomizationGroupId is required for delete mode.', 16, 1);
            RETURN;
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.CUSTOMIZATION_GROUPS WHERE CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID)
        BEGIN
            RAISERROR('Customization group not found.', 16, 1);
            RETURN;
        END;

        DELETE FROM dbo.CUSTOMIZATION_GROUPS
        WHERE CUSTOMIZATION_GROUP_ID = @CUSTOMIZATION_GROUP_ID;

        SELECT NULL AS CustomizationGroupId WHERE 1 = 0;
        RETURN;
    END;

    RAISERROR('Invalid Mode specified. Use ADD, EDIT, or DELETE.', 16, 1);
END;
GO
