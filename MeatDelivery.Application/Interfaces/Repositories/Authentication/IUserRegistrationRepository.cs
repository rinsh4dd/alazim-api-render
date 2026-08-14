using System;
using System.Threading.Tasks;

namespace MeatDelivery.Application.Interfaces.Repositories.Authentication
{
    public class CustomerRegistrationResult
    {
        public long UserId { get; set; }
        public string? DocType { get; set; }
        public string? DocNo { get; set; }
        public long SessionId { get; set; }
        public long UserRoleId { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string LanguageCode { get; set; } = "EN";
        public bool IsProfileCompleted { get; set; }
        public bool IsNewUser { get; set; }
        public string? RoleCode { get; set; }
    }

    public interface IUserRegistrationRepository
    {
        Task<CustomerRegistrationResult> RegisterCustomerAndSessionAsync(
            string countryCode,
            string mobileNumber,
            string? fullName,
            string languageCode,
            string refreshTokenHash,
            string? deviceId,
            string? deviceType,
            string? ipAddress,
            DateTime sessionExpiresAt);

        Task<CustomerRegistrationResult> VerifyOtpAndRegisterCustomerAsync(
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
            Guid? challengeId = null);
    }
}
