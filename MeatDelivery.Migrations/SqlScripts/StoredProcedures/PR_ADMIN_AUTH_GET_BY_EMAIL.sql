-- =============================================================================
-- STORED PROCEDURE: dbo.PR_ADMIN_AUTH_GET_BY_EMAIL
-- Description: Retrieves Admin user data along with assigned roles for authentication.
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_ADMIN_AUTH_GET_BY_EMAIL
    @EMAIL VARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;

    -- Return Admin User Data
    SELECT 
        u.ADMIN_USER_ID AS AdminUserId,
        u.DOCTYPE AS DocType,
        u.DOC_NO AS DocNo,
        u.EMAIL AS Email,
        u.PASSWORD_HASH AS PasswordHash,
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
        u.FAILED_LOGIN_COUNT AS FailedLoginCount,
        u.LOCKED_UNTIL AS LockedUntil,
        u.LAST_LOGIN_AT AS LastLoginAt,
        u.PASSWORD_CHANGED_AT AS PasswordChangedAt,
        u.IS_DELETED AS IsDeleted,
        u.DELETED_AT AS DeletedAt,
        u.CREATED_AT AS CreatedAt,
        u.UPDATED_AT AS UpdatedAt
    FROM dbo.ADMIN_USERS u
    WHERE u.EMAIL = @EMAIL
      AND (u.IS_DELETED = 0 OR u.IS_DELETED IS NULL);

    -- Return Assigned Roles
    SELECT 
        r.ROLE_CODE AS RoleCode,
        r.ROLE_NAME AS RoleName
    FROM dbo.ADMIN_USERS u
    INNER JOIN dbo.ADMIN_USER_ROLES ur ON ur.ADMIN_USER_ID = u.ADMIN_USER_ID AND ur.IS_ACTIVE = 1
    INNER JOIN dbo.ROLES r ON r.ROLE_ID = ur.ROLE_ID AND r.IS_ACTIVE = 1
    WHERE u.EMAIL = @EMAIL
      AND (u.IS_DELETED = 0 OR u.IS_DELETED IS NULL);
END;
GO
