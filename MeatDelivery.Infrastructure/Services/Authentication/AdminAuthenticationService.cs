using System;
using System.Collections.Generic;
using System.Security.Authentication;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Options;
using MeatDelivery.Application.Common.Security;
using MeatDelivery.Application.DTOs.Admin;
using MeatDelivery.Application.Interfaces.Authentication;
using MeatDelivery.Application.Interfaces.Repositories.Authentication;
using MeatDelivery.Domain.Enums;
using MeatDelivery.Infrastructure.Configurations;

namespace MeatDelivery.Infrastructure.Services.Authentication
{
    public sealed class AdminAuthenticationService : IAdminAuthenticationService
    {
        private readonly IAdminUserRepository _adminUserRepository;
        private readonly IAdminSessionRepository _adminSessionRepository;
        private readonly IPasswordHasher _passwordHasher;
        private readonly ITokenService _tokenService;
        private readonly JwtSettings _jwtSettings;

        public AdminAuthenticationService(
            IAdminUserRepository adminUserRepository,
            IAdminSessionRepository adminSessionRepository,
            IPasswordHasher passwordHasher,
            ITokenService tokenService,
            IOptions<JwtSettings> jwtOptions)
        {
            _adminUserRepository = adminUserRepository;
            _adminSessionRepository = adminSessionRepository;
            _passwordHasher = passwordHasher;
            _tokenService = tokenService;
            _jwtSettings = jwtOptions.Value;
        }

        public async Task<AdminAuthResponseDto> LoginAsync(
            AdminLoginRequestDto request,
            string? ipAddress,
            string? deviceId,
            string? userAgent,
            CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(request);

            var (user, roles) = await _adminUserRepository.GetByEmailWithRolesAsync(request.Email.Trim().ToLowerInvariant(), cancellationToken);

            if (user == null)
            {
                throw new InvalidCredentialException("Invalid email or password.");
            }

            // Check account lockout
            if (user.LockedUntil.HasValue && user.LockedUntil.Value > DateTime.UtcNow)
            {
                var remainingMinutes = Math.Ceiling((user.LockedUntil.Value - DateTime.UtcNow).TotalMinutes);
                throw new InvalidOperationException($"Account is temporarily locked due to multiple failed login attempts. Please try again in {remainingMinutes} minute(s).");
            }

            // Check active status
            if (user.AdminStatus != AdminStatus.ACTIVE)
            {
                throw new InvalidOperationException("Admin account is not active. Please contact a system administrator.");
            }

            // Verify password
            bool isPasswordValid = _passwordHasher.Verify(request.Password, user.PasswordHash);

            if (!isPasswordValid)
            {
                var (failedCount, lockedUntil) = await _adminUserRepository.RecordLoginFailureAsync(user.AdminUserId, maxAttempts: 5, lockoutMinutes: 15, cancellationToken);
                
                if (lockedUntil.HasValue)
                {
                    throw new InvalidOperationException("Maximum failed login attempts reached. Your account has been locked for 15 minutes.");
                }

                throw new InvalidCredentialException("Invalid email or password.");
            }

            // Check for automatic password re-hash upgrade
            string? upgradedPasswordHash = null;
            if (_passwordHasher.NeedsRehash(user.PasswordHash))
            {
                upgradedPasswordHash = _passwordHasher.Hash(request.Password);
            }

            // Record login success
            await _adminUserRepository.RecordLoginSuccessAsync(user.AdminUserId, upgradedPasswordHash, cancellationToken);

            // Create new refresh session
            string rawRefreshToken = _tokenService.GenerateRefreshToken();
            string refreshTokenHash = _tokenService.HashRefreshToken(rawRefreshToken);
            DateTime sessionExpiry = DateTime.UtcNow.AddDays(_jwtSettings.RefreshTokenExpiryDays);

            var session = new Domain.Entities.Authentication.AdminSession
            {
                AdminUserId = user.AdminUserId,
                RefreshTokenHash = refreshTokenHash,
                DeviceId = deviceId,
                IpAddress = ipAddress,
                UserAgent = userAgent,
                ExpiresAt = sessionExpiry,
                IsActive = true
            };

            long sessionId = await _adminSessionRepository.CreateSessionAsync(session, cancellationToken);

            // Generate JWT Access Token
            string accessToken = _tokenService.GenerateAccessTokenForAdmin(
                user.AdminUserId,
                user.Email,
                user.FullName,
                roles,
                sessionId);

            return new AdminAuthResponseDto
            {
                AdminUserId = user.AdminUserId,
                DocType = user.DocType,
                DocNo = user.DocNo,
                Email = user.Email,
                FirstName = user.FirstName,
                LastName = user.LastName ?? string.Empty,
                FullName = user.FullName,
                Roles = roles,
                AccessToken = accessToken,
                RefreshToken = rawRefreshToken,
                ExpiresIn = _jwtSettings.AccessTokenExpiryMinutes * 60
            };
        }

        public async Task<AdminAuthResponseDto> RefreshTokenAsync(
            AdminRefreshTokenRequestDto request,
            string? ipAddress,
            string? deviceId,
            string? userAgent,
            CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(request);

            if (string.IsNullOrWhiteSpace(request.RefreshToken))
            {
                throw new InvalidCredentialException("Refresh token is required.");
            }

            string currentTokenHash = _tokenService.HashRefreshToken(request.RefreshToken);
            string newRawRefreshToken = _tokenService.GenerateRefreshToken();
            string newRefreshTokenHash = _tokenService.HashRefreshToken(newRawRefreshToken);
            DateTime newSessionExpiry = DateTime.UtcNow.AddDays(_jwtSettings.RefreshTokenExpiryDays);

            var (user, roles, newSessionId) = await _adminSessionRepository.RefreshSessionAsync(
                currentTokenHash,
                newRefreshTokenHash,
                deviceId,
                ipAddress,
                userAgent,
                newSessionExpiry,
                cancellationToken);

            if (user == null || newSessionId == 0)
            {
                throw new InvalidCredentialException("Invalid or expired refresh token session.");
            }

            string accessToken = _tokenService.GenerateAccessTokenForAdmin(
                user.AdminUserId,
                user.Email,
                user.FullName,
                roles,
                newSessionId);

            return new AdminAuthResponseDto
            {
                AdminUserId = user.AdminUserId,
                DocType = user.DocType,
                DocNo = user.DocNo,
                Email = user.Email,
                FirstName = user.FirstName,
                LastName = user.LastName ?? string.Empty,
                FullName = user.FullName,
                Roles = roles,
                AccessToken = accessToken,
                RefreshToken = newRawRefreshToken,
                ExpiresIn = _jwtSettings.AccessTokenExpiryMinutes * 60
            };
        }

        public async Task LogoutAsync(
            string refreshToken,
            CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(refreshToken))
                return;

            string tokenHash = _tokenService.HashRefreshToken(refreshToken);
            await _adminSessionRepository.RevokeSessionAsync(tokenHash, cancellationToken);
        }

        public async Task<AdminProfileDto> GetProfileAsync(
            long adminUserId,
            CancellationToken cancellationToken = default)
        {
            var (user, roles) = await _adminUserRepository.GetByIdWithRolesAsync(adminUserId, cancellationToken);

            if (user == null)
            {
                throw new KeyNotFoundException("Admin user not found.");
            }

            return new AdminProfileDto
            {
                AdminUserId = user.AdminUserId,
                DocType = user.DocType,
                DocNo = user.DocNo,
                Email = user.Email,
                FirstName = user.FirstName,
                LastName = user.LastName ?? string.Empty,
                FullName = user.FullName,
                CountryCode = user.CountryCode,
                MobileNumber = user.MobileNumber,
                ProfileImageUrl = user.ProfileImageUrl,
                AdminStatus = user.AdminStatus.ToString(),
                Roles = roles,
                LastLoginAt = user.LastLoginAt,
                CreatedAt = user.CreatedAt
            };
        }
    }
}
