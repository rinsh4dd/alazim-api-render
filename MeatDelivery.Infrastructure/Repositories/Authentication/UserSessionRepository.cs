using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Authentication;
using MeatDelivery.Domain.Entities.Authentication;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace MeatDelivery.Infrastructure.Repositories.Authentication
{
    public class UserSessionRepository : IUserSessionRepository
    {
        private readonly IDapperRepository _dapperRepository;

        public UserSessionRepository(IDapperRepository dapperRepository)
        {
            _dapperRepository = dapperRepository;
        }

        public async Task<UserSession?> GetActiveSessionAsync(
            long userId,
            string refreshTokenHash,
            CancellationToken cancellationToken = default)
        {
            const string sql = @"
                SELECT 
                    SESSION_ID AS SessionId,
                    USER_ID AS UserId,
                    REFRESH_TOKEN_HASH AS RefreshTokenHash,
                    DEVICE_ID AS DeviceId,
                    DEVICE_TYPE AS DeviceType,
                    IP_ADDRESS AS IpAddress,
                    IS_ACTIVE AS IsActive,
                    EXPIRES_AT AS ExpiresAt,
                    LAST_ACTIVITY_AT AS LastActivityAt,
                    CREATED_AT AS CreatedAt,
                    UPDATED_AT AS UpdatedAt
                FROM dbo.USER_SESSIONS
                WHERE USER_ID = @UserId 
                  AND REFRESH_TOKEN_HASH = @RefreshTokenHash 
                  AND IS_ACTIVE = 1 
                  AND EXPIRES_AT > SYSUTCDATETIME()";

            return await _dapperRepository.QueryFirstOrDefaultAsync<UserSession>(
                sql,
                new { UserId = userId, RefreshTokenHash = refreshTokenHash });
        }

        public async Task<long> CreateSessionAsync(
            UserSession session,
            CancellationToken cancellationToken = default)
        {
            const string sql = @"
                INSERT INTO dbo.USER_SESSIONS
                (USER_ID, REFRESH_TOKEN_HASH, DEVICE_ID, DEVICE_TYPE, IP_ADDRESS, IS_ACTIVE, EXPIRES_AT, CREATED_AT)
                VALUES
                (@UserId, @RefreshTokenHash, @DeviceId, @DeviceType, @IpAddress, 1, @ExpiresAt, SYSUTCDATETIME());
                SELECT SCOPE_IDENTITY();";

            return await _dapperRepository.ExecuteScalarAsync<long>(
                sql,
                new
                {
                    UserId = session.UserId,
                    RefreshTokenHash = session.RefreshTokenHash,
                    DeviceId = session.DeviceId,
                    DeviceType = session.DeviceType,
                    IpAddress = session.IpAddress,
                    ExpiresAt = session.ExpiresAt
                });
        }

        public async Task RevokeSessionAsync(
            long sessionId,
            CancellationToken cancellationToken = default)
        {
            const string sql = @"
                UPDATE dbo.USER_SESSIONS
                SET IS_ACTIVE = 0,
                    UPDATED_AT = SYSUTCDATETIME()
                WHERE SESSION_ID = @SessionId";

            await _dapperRepository.ExecuteAsync(sql, new { SessionId = sessionId });
        }

        public async Task RevokeAllSessionsByUserIdAsync(
            long userId,
            CancellationToken cancellationToken = default)
        {
            await _dapperRepository.ExecuteAsync(
                "PR_AUTH_REVOKE_ALL_SESSIONS",
                new { UserId = userId });
        }

        public async Task<RefreshTokenSessionResult> RefreshTokenSessionAsync(
            string oldRefreshTokenHash,
            string newRefreshTokenHash,
            string? deviceId,
            string? deviceType,
            string? ipAddress,
            DateTime sessionExpiresAt,
            CancellationToken cancellationToken = default)
        {
            var result = await _dapperRepository.QueryFirstOrDefaultAsync<RefreshTokenSessionResult>(
                "PR_AUTH_REFRESH_TOKEN_SESSION",
                new
                {
                    OldRefreshTokenHash = oldRefreshTokenHash,
                    NewRefreshTokenHash = newRefreshTokenHash,
                    DeviceId = deviceId,
                    DeviceType = deviceType,
                    IpAddress = ipAddress,
                    SessionExpiresAt = sessionExpiresAt
                });

            return result ?? throw new InvalidOperationException("Failed to refresh token session.");
        }

        public async Task LogoutSessionAsync(string refreshTokenHash,CancellationToken cancellationToken = default)
        {
            await _dapperRepository.ExecuteAsync("PR_AUTH_LOGOUT_SESSION",new
                {
                    RefreshTokenHash = refreshTokenHash
                });
        }
    }
}
