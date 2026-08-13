using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Authentication;
using MeatDelivery.Domain.Entities.Authentication;

namespace MeatDelivery.Infrastructure.Repositories.Authentication
{
    public class OtpVerificationRepository : IOtpVerificationRepository
    {
        private readonly IDapperRepository _dapperRepository;

        public OtpVerificationRepository(IDapperRepository dapperRepository)
        {
            _dapperRepository = dapperRepository;
        }

        public async Task<bool> CheckMobileExistsAsync(string countryCode, string mobileNumber)
        {
            return await _dapperRepository.ExecuteScalarAsync<bool>(
                "PR_AUTH_CHECK_MOBILE_EXISTS",
                new { CountryCode = countryCode, MobileNumber = mobileNumber }
            );
        }

        public async Task<CreateOtpVerificationResult> CreateOtpVerificationAsync(string countryCode, string mobileNumber, string otpHash, string purpose, DateTime expiresAt, int maxAttempts = 5, Guid? challengeId = null)
        {
            var result = await _dapperRepository.QueryFirstOrDefaultAsync<CreateOtpVerificationResult>(
                "PR_AUTH_CREATE_OTP_VERIFICATION",
                new
                {
                    CountryCode = countryCode,
                    MobileNumber = mobileNumber,
                    OtpHash = otpHash,
                    OtpPurpose = purpose,
                    ExpiresAt = expiresAt,
                    MaxAttempts = maxAttempts,
                    ChallengeId = challengeId
                }
            );

            return result ?? new CreateOtpVerificationResult
            {
                IsSuccess = false,
                StatusCode = 0,
                Message = "Failed to initiate OTP verification."
            };
        }

        public async Task<OtpVerification?> GetLatestPendingOtpAsync(string countryCode, string mobileNumber, string purpose)
        {
            return await _dapperRepository.QueryFirstOrDefaultAsync<OtpVerification>(
                "PR_AUTH_GET_LATEST_PENDING_OTP",
                new
                {
                    CountryCode = countryCode,
                    MobileNumber = mobileNumber,
                    OtpPurpose = purpose
                }
            );
        }

        public async Task UpdateOtpStatusAsync(long otpId, string otpStatus, bool incrementAttempt = false)
        {
            await _dapperRepository.ExecuteAsync(
                "PR_AUTH_UPDATE_OTP_STATUS",
                new
                {
                    OtpId = otpId,
                    OtpStatus = otpStatus,
                    IncrementAttempt = incrementAttempt
                }
            );
        }
    }
}
