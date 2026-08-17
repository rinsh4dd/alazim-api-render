using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Dapper;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Authentication;
using MeatDelivery.Domain.Entities.Authentication;
using MeatDelivery.Infrastructure.Data;

namespace MeatDelivery.Infrastructure.Repositories.Authentication
{
    public class AdminSessionRepository : IAdminSessionRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public AdminSessionRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<long> CreateSessionAsync(AdminSession session, CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();
            var sessionId = await connection.ExecuteScalarAsync<long>(
                "dbo.PR_ADMIN_AUTH_CREATE_SESSION",
                new
                {
                    ADMIN_USER_ID = session.AdminUserId,
                    REFRESH_TOKEN_HASH = session.RefreshTokenHash,
                    DEVICE_ID = session.DeviceId,
                    IP_ADDRESS = session.IpAddress,
                    USER_AGENT = session.UserAgent,
                    EXPIRES_AT = session.ExpiresAt
                },
                commandType: CommandType.StoredProcedure);

            return sessionId;
        }

        public async Task<(AdminUser? User, List<string> Roles, long NewSessionId)> RefreshSessionAsync(
            string currentRefreshTokenHash,
            string newRefreshTokenHash,
            string? deviceId,
            string? ipAddress,
            string? userAgent,
            DateTime newExpiresAt,
            CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();
            using var multi = await connection.QueryMultipleAsync(
                "dbo.PR_ADMIN_AUTH_REFRESH_SESSION",
                new
                {
                    CURRENT_REFRESH_TOKEN_HASH = currentRefreshTokenHash,
                    NEW_REFRESH_TOKEN_HASH = newRefreshTokenHash,
                    DEVICE_ID = deviceId,
                    IP_ADDRESS = ipAddress,
                    USER_AGENT = userAgent,
                    NEW_EXPIRES_AT = newExpiresAt
                },
                commandType: CommandType.StoredProcedure);

            var userRow = await multi.ReadSingleOrDefaultAsync<dynamic>();
            if (userRow == null)
            {
                return (null, new List<string>(), 0);
            }

            var user = new AdminUser
            {
                AdminUserId = (long)userRow.AdminUserId,
                DocType = (string?)userRow.DocType,
                DocNo = (string?)userRow.DocNo,
                Email = (string)userRow.Email,
                FirstName = (string)userRow.FirstName,
                LastName = (string)userRow.LastName
            };

            long newSessionId = (long)userRow.NewSessionId;

            var roleRows = await multi.ReadAsync<dynamic>();
            var roles = roleRows.Select(r => (string)r.RoleCode).ToList();

            return (user, roles, newSessionId);
        }

        public async Task RevokeSessionAsync(string refreshTokenHash, CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();
            await connection.ExecuteAsync(
                "dbo.PR_ADMIN_AUTH_LOGOUT_SESSION",
                new { REFRESH_TOKEN_HASH = refreshTokenHash },
                commandType: CommandType.StoredProcedure);
        }
    }
}
