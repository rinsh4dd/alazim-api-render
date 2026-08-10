using MeatDelivery.Application.DTOs.Auth;
using MeatDelivery.Application.Interfaces.Authentication;
using MeatDelivery.Application.Interfaces.Repositories.Authentication;
using MeatDelivery.Infrastructure.Configurations;
using System;
using System.Collections.Generic;
using System.Text;

namespace MeatDelivery.Infrastructure.Services.Authentication
{
    public sealed class AuthenticationService : IAuthenticationService
    {
        private readonly IUserRepository _userRepository;
        private readonly IRefreshTokenRepository _refreshTokenRepository;
        private readonly IPasswordHasher _passwordHasher;
        private readonly ITokenService _tokenService;
        private readonly IRefreshTokenService _refreshTokenService;
        private readonly MeatDelivery.Application.Interfaces.Logging.IActivityLogService _activityLogService;
        private readonly JwtSettings _jwtSettings;

        public AuthenticationService(
            IUserRepository userRepository,
            IRefreshTokenRepository refreshTokenRepository,
            IPasswordHasher passwordHasher,
            ITokenService tokenService,
            IRefreshTokenService refreshTokenService,
            MeatDelivery.Application.Interfaces.Logging.IActivityLogService activityLogService,
            Microsoft.Extensions.Options.IOptions<JwtSettings> jwtOptions)
        {
            _userRepository = userRepository;
            _refreshTokenRepository = refreshTokenRepository;
            _passwordHasher = passwordHasher;
            _tokenService = tokenService;
            _refreshTokenService = refreshTokenService;
            _activityLogService = activityLogService;
            _jwtSettings = jwtOptions.Value;
        }

        public async Task<LoginResponseDto> LoginAsync(
            LoginRequestDto request,
            string ipAddress,
            string userAgent,
            CancellationToken cancellationToken = default)
        {
            Guid sessionId = Guid.NewGuid();

            var user = await _userRepository.GetByUsernameAsync(
                request.UserNameOrEmail,
                cancellationToken);

            if (user is null)
                throw new UnauthorizedAccessException("Invalid username or password.");

            if (!user.IsActive)
                throw new UnauthorizedAccessException("User account is inactive.");

            if (!_passwordHasher.VerifyPassword(request.Password, user.PasswordHash))
                throw new UnauthorizedAccessException("Invalid username or password.");

            var userData = await _userRepository.GetUserContextAsync(
                user.UserId,
                cancellationToken);

            var accessToken = _tokenService.GenerateAccessToken(userData, sessionId);

            var refreshToken = _refreshTokenService.GenerateToken();
            var refreshTokenExpiry = DateTime.UtcNow.AddDays(_jwtSettings.RefreshTokenExpiryDays);

            await _refreshTokenRepository.SaveAsync(sessionId,
                userData.UserId,
                refreshToken,
                refreshTokenExpiry,
                ipAddress,
                userAgent,
                cancellationToken);

            await _userRepository.UpdateLastLoginAsync(
                user.UserId,
                cancellationToken);

            // Log the successful login activity
            await _activityLogService.LogActivityAsync(
                userId: user.UserId,
                activityType: "UserLoggedIn",
                description: $"User '{user.Username}' logged in successfully from IP: {ipAddress}.",
                source: "AuthenticationService",
                referenceId: sessionId.ToString(),
                cancellationToken: cancellationToken);

            return new LoginResponseDto
            {
                Success = true,
                Message = "Login successful",
                AccessToken = accessToken,
                RefreshToken = refreshToken,
                ExpiresAtUtc = DateTime.UtcNow.AddMinutes(_jwtSettings.AccessTokenExpiryMinutes),
                User = userData
            };
        }

        public async Task<LoginResponseDto> RefreshTokenAsync(
            RefreshTokenRequestDto request,
            string ipAddress,
            CancellationToken cancellationToken = default)
        {
            var userId = _tokenService.GetUserIdFromExpiredToken(request.AccessToken);
            if (userId == null)
                throw new UnauthorizedAccessException("Invalid access token.");

            var userData = await _userRepository.GetUserContextAsync(
                userId.Value,
                cancellationToken);

            if (userData is null)
                throw new UnauthorizedAccessException("User account is inactive or not found.");

            var isValid = await _refreshTokenRepository.ValidateAsync(
                userData.UserId,
                request.RefreshToken,
                cancellationToken);

            if (!isValid)
                throw new UnauthorizedAccessException("Invalid or expired refresh token.");

            await _refreshTokenRepository.RevokeAsync(
                request.RefreshToken,
                cancellationToken);

            Guid newSessionId = Guid.NewGuid();
            var accessToken = _tokenService.GenerateAccessToken(userData, newSessionId);

            var newRefreshToken = _refreshTokenService.GenerateToken();
            var refreshTokenExpiry = DateTime.UtcNow.AddDays(_jwtSettings.RefreshTokenExpiryDays);

            await _refreshTokenRepository.SaveAsync(
                newSessionId,
                userData.UserId,
                newRefreshToken,
                refreshTokenExpiry,
                ipAddress,
                "Unknown",
                cancellationToken);

            return new LoginResponseDto
            {
                Success = true,
                Message = "Token refreshed successfully",
                AccessToken = accessToken,
                RefreshToken = newRefreshToken,
                ExpiresAtUtc = DateTime.UtcNow.AddMinutes(_jwtSettings.AccessTokenExpiryMinutes),
                User = userData
            };
        }

        public async Task LogoutAsync(
            Guid userId,
            string refreshToken,
            CancellationToken cancellationToken = default)
        {
            var userData = await _userRepository.GetUserContextAsync(
                userId,
                cancellationToken);

            if (userData is null)
                return;

            var isValid = await _refreshTokenRepository.ValidateAsync(
                userData.UserId,
                refreshToken,
                cancellationToken);

            if (isValid)
            {
                await _refreshTokenRepository.RevokeAsync(
                    refreshToken,
                    cancellationToken);
            }
        }

        public async Task RevokeAllSessionsAsync(
            Guid userId,
            CancellationToken cancellationToken = default)
        {
            var userData = await _userRepository.GetUserContextAsync(
                userId,
                cancellationToken);

            if (userData != null)
            {
                await _refreshTokenRepository.RevokeAllByUserIdAsync(
                    userData.UserId,
                    cancellationToken);
            }
        }

        public async Task<UserContextDto?> GetCurrentUserAsync(
            Guid userId,
            CancellationToken cancellationToken = default)
        {
            return await _userRepository.GetUserContextAsync(
                userId,
                cancellationToken);
        }

        public async Task<Guid> RegisterUserAsync(
            RegisterRequestDto request,
            CancellationToken cancellationToken = default)
        {
            var createUserDto = new CreateUserDto
            {
                Username = request.Username,
                Email = request.Email,
                PasswordHash = _passwordHasher.HashPassword(request.Password),
                FirstName = request.FirstName,
                LastName = request.LastName,
                PhoneNumber = request.PhoneNumber,
                RoleId = request.RoleId
            };

            var newUserId = await _userRepository.CreateUserAsync(createUserDto, cancellationToken);

            // Log the successful registration activity
            await _activityLogService.LogActivityAsync(
                userId: newUserId,
                activityType: "UserRegistered",
                description: $"New user '{request.Username}' was registered.",
                source: "AuthenticationService",
                referenceId: newUserId.ToString(),
                cancellationToken: cancellationToken);

            return newUserId;
        }
    }
}
