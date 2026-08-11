using MeatDelivery.Domain.Entities.Authentication;

namespace MeatDelivery.Application.Interfaces.Repositories.Authentication
{
    public interface IOtpVerificationRepository
    {
        Task<bool> CheckMobileExistsAsync(string countryCode, string mobileNumber);
        Task<(long OtpId, Guid ChallengeId)> CreateOtpVerificationAsync(string countryCode, string mobileNumber, string otpHash, string purpose, DateTime expiresAt, int maxAttempts = 5, Guid? challengeId = null);
        Task<OtpVerification?> GetLatestPendingOtpAsync(string countryCode, string mobileNumber, string purpose);
        Task UpdateOtpStatusAsync(long otpId, string otpStatus, bool incrementAttempt = false);
    }
}
