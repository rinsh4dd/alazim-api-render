using MeatDelivery.Application.DTOs.Auth;
using System.Threading;
using System.Threading.Tasks;

namespace MeatDelivery.Application.Interfaces.Authentication
{
    public interface IAuthenticationService
    {
        Task<SendOtpResponseDto> SendOtpAsync(
            SendOtpRequestDto request,
            CancellationToken cancellationToken = default);

        Task<AuthTokenResponseDto> AuthenticateWithOtpAsync(
            VerifyOtpRequestDto request,
            string ipAddress,
            string? deviceId = null,
            string? deviceType = null,
            CancellationToken cancellationToken = default);

        Task<AuthTokenResponseDto> RefreshTokenAsync(
            RefreshTokenRequestDto request,
            string ipAddress,
            string? deviceId = null,
            string? deviceType = null,
            CancellationToken cancellationToken = default);

        Task LogoutAsync(
            LogoutRequestDto request,
            CancellationToken cancellationToken = default);

        Task RevokeAllSessionsAsync(
            long userId,
            CancellationToken cancellationToken = default);
    }
}
