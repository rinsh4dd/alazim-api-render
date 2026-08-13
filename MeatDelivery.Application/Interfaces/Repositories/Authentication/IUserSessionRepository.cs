using MeatDelivery.Domain.Entities.Authentication;
using System.Threading;
using System.Threading.Tasks;

namespace MeatDelivery.Application.Interfaces.Repositories.Authentication
{
    public class RefreshTokenSessionResult
    {
        public long UserId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string CountryCode { get; set; } = string.Empty;
        public string MobileNumber { get; set; } = string.Empty;
        public long SessionId { get; set; }
    }

    public interface IUserSessionRepository
    {
        Task<UserSession?> GetActiveSessionAsync(
            long userId,
            string refreshTokenHash,
            CancellationToken cancellationToken = default);

        Task<long> CreateSessionAsync(
            UserSession session,
            CancellationToken cancellationToken = default);

        Task RevokeSessionAsync(
            long sessionId,
            CancellationToken cancellationToken = default);

        Task RevokeAllSessionsByUserIdAsync(
            long userId,
            CancellationToken cancellationToken = default);

        Task<RefreshTokenSessionResult> RefreshTokenSessionAsync(
            string oldRefreshTokenHash,
            string newRefreshTokenHash,
            string? deviceId,
            string? deviceType,
            string? ipAddress,
            DateTime sessionExpiresAt,
            CancellationToken cancellationToken = default);

        Task LogoutSessionAsync(
            string refreshTokenHash,
            CancellationToken cancellationToken = default);
    }
}
