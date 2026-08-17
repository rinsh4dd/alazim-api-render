using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Admin;

namespace MeatDelivery.Application.Interfaces.Authentication
{
    public interface IAdminAuthenticationService
    {
        Task<AdminAuthResponseDto> LoginAsync(
            AdminLoginRequestDto request,
            string? ipAddress,
            string? deviceId,
            string? userAgent,
            CancellationToken cancellationToken = default);

        Task<AdminProfileDto> GetProfileAsync(
            long adminUserId,
            CancellationToken cancellationToken = default);
    }
}
