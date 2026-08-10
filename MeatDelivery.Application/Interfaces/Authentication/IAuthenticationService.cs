using MeatDelivery.Application.DTOs.Auth;
using System;
using System.Collections.Generic;
using System.Text;

namespace MeatDelivery.Application.Interfaces.Authentication
{
    public interface IAuthenticationService
    {
        Task<LoginResponseDto> LoginAsync(
            LoginRequestDto request,
            string ipAddress,
            string userAgent,
            CancellationToken cancellationToken = default);

        Task<LoginResponseDto> RefreshTokenAsync(
            RefreshTokenRequestDto request,
            string ipAddress,
            CancellationToken cancellationToken = default);

        Task LogoutAsync(
            Guid userId,
            string refreshToken,
            CancellationToken cancellationToken = default);

        Task RevokeAllSessionsAsync(
            Guid userId,
            CancellationToken cancellationToken = default);

        Task<UserContextDto?> GetCurrentUserAsync(
            Guid userId,
            CancellationToken cancellationToken = default);

        Task<Guid> RegisterUserAsync(
            RegisterRequestDto request,
            CancellationToken cancellationToken = default);
    }
}
