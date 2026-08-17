-- =============================================================================
-- STORED PROCEDURE: dbo.PR_CUSTOMER_GET_PROFILE
-- =============================================================================

CREATE OR ALTER PROCEDURE dbo.PR_CUSTOMER_GET_PROFILE
    @USER_ID BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        u.USER_ID AS UserId,
        u.DOCTYPE AS DocType,
        u.DOC_NO AS DocNo,
        u.COUNTRY_CODE AS CountryCode,
        u.MOBILE_NUMBER AS MobileNumber,
        u.EMAIL AS Email,
        u.FIRST_NAME AS FirstName,
        u.LAST_NAME AS LastName,
        ISNULL(LTRIM(RTRIM(ISNULL(u.FIRST_NAME, '') + ' ' + ISNULL(u.LAST_NAME, ''))), '') AS FullName,
        u.DOB AS Dob,
        u.GENDER AS Gender,
        u.PROFILE_IMAGE_URL AS ProfileImageUrl,
        u.LANGUAGE_CODE AS LanguageCode,
        u.IS_MOBILE_VERIFIED AS IsMobileVerified,
        u.IS_EMAIL_VERIFIED AS IsEmailVerified,
        u.ELIGIBLE_FOR_ORDER AS EligibleForOrder,
        u.IS_PROFILE_COMPLETED AS IsProfileCompleted,
        u.USER_STATUS AS UserStatus,
        u.CREATED_AT AS CreatedAt,
        u.UPDATED_AT AS UpdatedAt
    FROM dbo.CUSTOMER_USERS u
    WHERE u.USER_ID = @USER_ID;
END;
GO
