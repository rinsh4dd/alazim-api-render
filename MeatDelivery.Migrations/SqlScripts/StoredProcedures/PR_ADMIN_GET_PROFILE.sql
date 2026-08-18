-- =============================================================================
-- STORED PROCEDURE: dbo.PR_ADMIN_GET_PROFILE
-- Description: Retrieves full profile details and assigned roles of an admin user.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_ADMIN_GET_PROFILE
    @ADMIN_USER_ID BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    -- Return Admin Profile
    SELECT 
        u.ADMIN_USER_ID AS AdminUserId,
        u.DOCTYPE AS DocType,
        u.DOC_NO AS DocNo,
        u.EMAIL AS Email,
        u.FIRST_NAME AS FirstName,
        u.LAST_NAME AS LastName,
        ISNULL(LTRIM(RTRIM(ISNULL(u.FIRST_NAME, '') + ' ' + ISNULL(u.LAST_NAME, ''))), '') AS FullName,
        u.COUNTRY_CODE AS CountryCode,
        u.MOBILE_NUMBER AS MobileNumber,
        u.PROFILE_IMAGE_URL AS ProfileImageUrl,
        u.NATIONALITY AS Nationality,
        u.DOB AS Dob,
        u.ADDRESS AS Address,
        u.ADMIN_STATUS AS AdminStatus,
        u.LAST_LOGIN_AT AS LastLoginAt,
        u.CREATED_AT AS CreatedAt,
        u.UPDATED_AT AS UpdatedAt
    FROM dbo.ADMIN_USERS u
    WHERE u.ADMIN_USER_ID = @ADMIN_USER_ID;

    -- Return Roles
    SELECT 
        r.ROLE_CODE AS RoleCode,
        r.ROLE_NAME AS RoleName,
        r.DESCRIPTION AS Description
    FROM dbo.ADMIN_USER_ROLES ur
    INNER JOIN dbo.ROLES r ON r.ROLE_ID = ur.ROLE_ID AND r.IS_ACTIVE = 1
    WHERE ur.ADMIN_USER_ID = @ADMIN_USER_ID AND ur.IS_ACTIVE = 1;
END;
GO
