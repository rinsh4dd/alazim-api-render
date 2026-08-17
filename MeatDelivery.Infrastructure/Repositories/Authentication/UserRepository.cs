using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Authentication;
using MeatDelivery.Domain.Entities.Authentication;

namespace MeatDelivery.Infrastructure.Repositories.Authentication
{
    public sealed class UserRepository : IUserRepository
    {
        private readonly IDapperRepository _repository;

        public UserRepository(IDapperRepository repository)
        {
            _repository = repository;
        }

        public async Task<User?> GetByIdAsync(long userId, CancellationToken cancellationToken = default)
        {
            return await _repository.QueryFirstOrDefaultAsync<User>(
                "SELECT USER_ID AS UserId, DOCTYPE AS DocType, DOC_NO AS DocNo, COUNTRY_CODE AS CountryCode, MOBILE_NUMBER AS MobileNumber, EMAIL AS Email, FIRST_NAME AS FirstName, LAST_NAME AS LastName, DOB AS Dob, GENDER AS Gender, PROFILE_IMAGE_URL AS ProfileImageUrl, LANGUAGE_CODE AS LanguageCode, IS_MOBILE_VERIFIED AS IsMobileVerified, IS_EMAIL_VERIFIED AS IsEmailVerified, ELIGIBLE_FOR_ORDER AS EligibleForOrder, IS_PROFILE_COMPLETED AS IsProfileCompleted, USER_STATUS AS UserStatus, LAST_LOGIN_AT AS LastLoginAt, CREATED_AT AS CreatedAt, UPDATED_AT AS UpdatedAt FROM dbo.CUSTOMER_USERS WHERE USER_ID = @UserId",
                new { UserId = userId });
        }

        public async Task<User?> GetByMobileAsync(string countryCode, string mobileNumber, CancellationToken cancellationToken = default)
        {
            return await _repository.QueryFirstOrDefaultAsync<User>(
                "SELECT USER_ID AS UserId, DOCTYPE AS DocType, DOC_NO AS DocNo, COUNTRY_CODE AS CountryCode, MOBILE_NUMBER AS MobileNumber, EMAIL AS Email, FIRST_NAME AS FirstName, LAST_NAME AS LastName, DOB AS Dob, GENDER AS Gender, PROFILE_IMAGE_URL AS ProfileImageUrl, LANGUAGE_CODE AS LanguageCode, IS_MOBILE_VERIFIED AS IsMobileVerified, IS_EMAIL_VERIFIED AS IsEmailVerified, ELIGIBLE_FOR_ORDER AS EligibleForOrder, IS_PROFILE_COMPLETED AS IsProfileCompleted, USER_STATUS AS UserStatus, LAST_LOGIN_AT AS LastLoginAt, CREATED_AT AS CreatedAt, UPDATED_AT AS UpdatedAt FROM dbo.CUSTOMER_USERS WHERE COUNTRY_CODE = @CountryCode AND MOBILE_NUMBER = @MobileNumber",
                new { CountryCode = countryCode, MobileNumber = mobileNumber });
        }
    }
}
