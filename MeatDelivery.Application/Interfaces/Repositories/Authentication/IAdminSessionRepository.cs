using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Domain.Entities.Authentication;

namespace MeatDelivery.Application.Interfaces.Repositories.Authentication
{
    public interface IAdminSessionRepository
    {
        Task<long> CreateSessionAsync(AdminSession session, CancellationToken cancellationToken = default);
        Task<(AdminUser? User, List<string> Roles, long NewSessionId)> RefreshSessionAsync(
            string currentRefreshTokenHash,
            string newRefreshTokenHash,
            string? deviceId,
            string? ipAddress,
            string? userAgent,
            DateTime newExpiresAt,
            CancellationToken cancellationToken = default);
        Task RevokeSessionAsync(string refreshTokenHash, CancellationToken cancellationToken = default);
    }
}
