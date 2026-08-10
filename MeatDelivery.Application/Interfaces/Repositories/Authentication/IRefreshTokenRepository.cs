using System;
using System.Collections.Generic;
using System.Text;

namespace MeatDelivery.Application.Interfaces.Repositories.Authentication
{
    public interface IRefreshTokenRepository
    {
        Task SaveAsync(
            Guid sessionId,
            Guid userId,
            string refreshToken,
            DateTime expiresOn,
            string? ipAddress,
            string? userAgent,
            CancellationToken cancellationToken = default);

        Task<bool> ValidateAsync(
            Guid userId,
            string refreshToken,
            CancellationToken cancellationToken = default);

       Task RevokeAsync(
            string refreshToken,
            CancellationToken cancellationToken = default);

        Task RevokeAllByUserIdAsync(
            Guid userId,
            CancellationToken cancellationToken = default);
    }
}
