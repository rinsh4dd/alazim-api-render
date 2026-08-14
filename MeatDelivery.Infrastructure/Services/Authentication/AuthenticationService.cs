using MeatDelivery.Application.DTOs.Auth;
using MeatDelivery.Application.Interfaces.Authentication;
using MeatDelivery.Application.Interfaces.Repositories.Authentication;
using MeatDelivery.Domain.Entities.Authentication;
using MeatDelivery.Infrastructure.Configurations;
using MeatDelivery.Shared.Responses;
using Microsoft.Extensions.Options;

namespace MeatDelivery.Infrastructure.Services.Authentication
{
    public sealed class AuthenticationService : IAuthenticationService
    {
        private readonly IUserRepository _userRepository;
        private readonly IOtpVerificationRepository _otpVerificationRepository;
        private readonly IUserRegistrationRepository _userRegistrationRepository;
        private readonly IUserSessionRepository _userSessionRepository;
        private readonly ITokenService _tokenService;
        private readonly IOtpService _otpService;
        private readonly JwtSettings _jwtSettings;

        public AuthenticationService(
            IUserRepository userRepository,
            IOtpVerificationRepository otpVerificationRepository,
            IUserRegistrationRepository userRegistrationRepository,
            IUserSessionRepository userSessionRepository,
            ITokenService tokenService,
            IOtpService otpService,
            IOptions<JwtSettings> jwtOptions)
        {
            _userRepository = userRepository;
            _otpVerificationRepository = otpVerificationRepository;
            _userRegistrationRepository = userRegistrationRepository;
            _userSessionRepository = userSessionRepository;
            _tokenService = tokenService;
            _otpService = otpService;
            _jwtSettings = jwtOptions.Value;
        }

        public async Task<ApiResponse<SendOtpResponseDto>> SendOtpAsync(SendOtpRequestDto request, CancellationToken cancellationToken = default)
        {
            string otpCode = _otpService.GenerateOtpCode();
            string otpHash = _otpService.HashOtpCode(otpCode, request.CountryCode, request.MobileNumber);
            DateTime expiresAt = DateTime.UtcNow.AddMinutes(5);
            Guid challengeId = Guid.NewGuid();

            var otpResult = await _otpVerificationRepository.CreateOtpVerificationAsync(
                request.CountryCode,
                request.MobileNumber,
                otpHash,
                "AUTHENTICATION",
                expiresAt,
                maxAttempts: 5,
                challengeId: challengeId);

            if (!otpResult.IsSuccess)
            {
                return ApiResponse<SendOtpResponseDto>.FailureResponse(
                    message: otpResult.Message,
                    interval: otpResult.Interval,
                    status: otpResult.StatusCode);
            }

            var dto = new SendOtpResponseDto
            {
                ChallengeId = otpResult.ChallengeId != Guid.Empty ? otpResult.ChallengeId : challengeId,
                CountryCode = request.CountryCode,
                MobileNumber = request.MobileNumber,
                ExpiresAt = expiresAt,
                Interval = otpResult.Interval,
                DevOtpCode = otpCode
            };

            return ApiResponse<SendOtpResponseDto>.SuccessResponse(
                dto,
                message: otpResult.Message,
                interval: otpResult.Interval);
        }

        public async Task<AuthTokenResponseDto> AuthenticateWithOtpAsync(VerifyOtpRequestDto request, string ipAddress, string? deviceId = null, string? deviceType = null, CancellationToken cancellationToken = default)
        {
            string otpHash = _otpService.HashOtpCode(request.OtpCode, request.CountryCode, request.MobileNumber);
            string rawRefreshToken = _tokenService.GenerateRefreshToken();
            string refreshTokenHash = _tokenService.HashRefreshToken(rawRefreshToken);
            DateTime sessionExpiry = DateTime.UtcNow.AddDays(_jwtSettings.RefreshTokenExpiryDays);

            var regResult = await _userRegistrationRepository.VerifyOtpAndRegisterCustomerAsync(
                request.CountryCode,
                request.MobileNumber,
                otpHash,
                null,
                "EN",
                refreshTokenHash,
                deviceId,
                deviceType,
                ipAddress,
                sessionExpiry,
                maxAttempts: 5,
                challengeId: request.ChallengeId);

            string accessToken = _tokenService.GenerateAccessTokenForUser(
                regResult.UserId,
                regResult.FullName,
                request.CountryCode,
                request.MobileNumber,
                sessionId: regResult.SessionId);

            return new AuthTokenResponseDto
            {
                UserId = regResult.UserId,
                DocType = regResult.DocType,
                DocNo = regResult.DocNo,
                FirstName = regResult.FirstName,
                LastName = regResult.LastName,
                FullName = regResult.FullName,
                CountryCode = request.CountryCode,
                MobileNumber = request.MobileNumber,
                EligibleForOrder = regResult.EligibleForOrder,
                IsProfileCompleted = regResult.IsProfileCompleted,
                IsNewUser = regResult.IsNewUser,
                AccessToken = accessToken,
                RefreshToken = rawRefreshToken
            };
        }

        public async Task<AuthTokenResponseDto> RefreshTokenAsync(
            RefreshTokenRequestDto request,
            string ipAddress,
            string? deviceId = null,
            string? deviceType = null,
            CancellationToken cancellationToken = default)
        {
            string oldRefreshTokenHash = _tokenService.HashRefreshToken(request.RefreshToken);
            string newRawRefreshToken = _tokenService.GenerateRefreshToken();
            string newRefreshTokenHash = _tokenService.HashRefreshToken(newRawRefreshToken);
            DateTime sessionExpiry = DateTime.UtcNow.AddDays(_jwtSettings.RefreshTokenExpiryDays);

            var sessionResult = await _userSessionRepository.RefreshTokenSessionAsync(
                oldRefreshTokenHash,
                newRefreshTokenHash,
                deviceId ?? request.DeviceId,
                deviceType ?? request.DeviceType,
                ipAddress,
                sessionExpiry,
                cancellationToken);

            string accessToken = _tokenService.GenerateAccessTokenForUser(
                sessionResult.UserId,
                sessionResult.FullName,
                sessionResult.CountryCode,
                sessionResult.MobileNumber,
                sessionId: sessionResult.SessionId);

            return new AuthTokenResponseDto
            {
                UserId = sessionResult.UserId,
                FullName = sessionResult.FullName,
                CountryCode = sessionResult.CountryCode,
                MobileNumber = sessionResult.MobileNumber,
                IsNewUser = false,
                AccessToken = accessToken,
                RefreshToken = newRawRefreshToken
            };
        }

        public async Task LogoutAsync(LogoutRequestDto request, CancellationToken cancellationToken = default)
        {
            string refreshTokenHash = _tokenService.HashRefreshToken(request.RefreshToken);
            await _userSessionRepository.LogoutSessionAsync(refreshTokenHash, cancellationToken);
        }

        public async Task RevokeAllSessionsAsync(
            long userId,
            CancellationToken cancellationToken = default)
        {
            await _userSessionRepository.RevokeAllSessionsByUserIdAsync(userId, cancellationToken);
        }
    }
}
