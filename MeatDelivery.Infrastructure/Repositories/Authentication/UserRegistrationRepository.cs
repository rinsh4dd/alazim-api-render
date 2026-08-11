using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Authentication;
using System;
using System.Threading.Tasks;

namespace MeatDelivery.Infrastructure.Repositories.Authentication
{
    public class UserRegistrationRepository : IUserRegistrationRepository
    {
        private readonly IDapperRepository _dapperRepository;

        public UserRegistrationRepository(IDapperRepository dapperRepository)
        {
            _dapperRepository = dapperRepository;
        }

        public async Task<CustomerRegistrationResult> RegisterCustomerAndSessionAsync(
            string countryCode,
            string mobileNumber,
            string? fullName,
            string languageCode,
            string refreshTokenHash,
            string? deviceId,
            string? deviceType,
            string? ipAddress,
            DateTime sessionExpiresAt)
        {
            var result = await _dapperRepository.QueryFirstOrDefaultAsync<CustomerRegistrationResult>(
                "PR_AUTH_REGISTER_CUSTOMER_AND_SESSION",
                new
                {
                    CountryCode = countryCode,
                    MobileNumber = mobileNumber,
                    FullName = fullName,
                    LanguageCode = languageCode,
                    RefreshTokenHash = refreshTokenHash,
                    DeviceId = deviceId,
                    DeviceType = deviceType,
                    IpAddress = ipAddress,
                    SessionExpiresAt = sessionExpiresAt
                }
            );

            return result ?? throw new InvalidOperationException("Failed to process customer authentication and session.");
        }

        public async Task<CustomerRegistrationResult> VerifyOtpAndRegisterCustomerAsync(
            string countryCode,
            string mobileNumber,
            string otpHash,
            string? fullName,
            string languageCode,
            string refreshTokenHash,
            string? deviceId,
            string? deviceType,
            string? ipAddress,
            DateTime sessionExpiresAt,
            int maxAttempts = 5,
            Guid? challengeId = null)
        {
            var result = await _dapperRepository.QueryFirstOrDefaultAsync<CustomerRegistrationResult>(
                "PR_AUTH_VERIFY_OTP_AND_REGISTER_CUSTOMER",
                new
                {
                    CountryCode = countryCode,
                    MobileNumber = mobileNumber,
                    OtpHash = otpHash,
                    FullName = fullName,
                    LanguageCode = languageCode,
                    RefreshTokenHash = refreshTokenHash,
                    DeviceId = deviceId,
                    DeviceType = deviceType,
                    IpAddress = ipAddress,
                    SessionExpiresAt = sessionExpiresAt,
                    MaxAttempts = maxAttempts,
                    ChallengeId = challengeId
                }
            );

            return result ?? throw new InvalidOperationException("Failed to verify OTP and register customer session.");
        }
    }
}
