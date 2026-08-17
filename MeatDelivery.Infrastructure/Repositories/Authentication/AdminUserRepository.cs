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
    public class AdminUserRepository : IAdminUserRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public AdminUserRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<(AdminUser? User, List<string> Roles)> GetByEmailWithRolesAsync(string email, CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();
            using var multi = await connection.QueryMultipleAsync(
                "dbo.PR_ADMIN_AUTH_GET_BY_EMAIL",
                new { EMAIL = email },
                commandType: CommandType.StoredProcedure);

            var user = await multi.ReadSingleOrDefaultAsync<AdminUser>();
            var roleRows = await multi.ReadAsync<dynamic>();
            var roles = roleRows.Select(r => (string)r.RoleCode).ToList();

            return (user, roles);
        }

        public async Task<(AdminUser? User, List<string> Roles)> GetByIdWithRolesAsync(long adminUserId, CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();
            using var multi = await connection.QueryMultipleAsync(
                "dbo.PR_ADMIN_GET_PROFILE",
                new { ADMIN_USER_ID = adminUserId },
                commandType: CommandType.StoredProcedure);

            var user = await multi.ReadSingleOrDefaultAsync<AdminUser>();
            var roleRows = await multi.ReadAsync<dynamic>();
            var roles = roleRows.Select(r => (string)r.RoleCode).ToList();

            return (user, roles);
        }

        public async Task RecordLoginSuccessAsync(long adminUserId, string? upgradedPasswordHash = null, CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();
            await connection.ExecuteAsync(
                "dbo.PR_ADMIN_AUTH_RECORD_LOGIN_SUCCESS",
                new
                {
                    ADMIN_USER_ID = adminUserId,
                    UPGRADED_PASSWORD_HASH = upgradedPasswordHash
                },
                commandType: CommandType.StoredProcedure);
        }

        public async Task<(int FailedCount, DateTime? LockedUntil)> RecordLoginFailureAsync(long adminUserId, int maxAttempts = 5, int lockoutMinutes = 15, CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();
            var result = await connection.QuerySingleOrDefaultAsync<dynamic>(
                "dbo.PR_ADMIN_AUTH_RECORD_LOGIN_FAILURE",
                new
                {
                    ADMIN_USER_ID = adminUserId,
                    MAX_ATTEMPTS = maxAttempts,
                    LOCKOUT_MINUTES = lockoutMinutes
                },
                commandType: CommandType.StoredProcedure);

            if (result == null)
            {
                return (0, null);
            }

            int count = (int)result.FailedLoginCount;
            DateTime? lockedUntil = result.LockedUntil != null ? (DateTime)result.LockedUntil : null;
            return (count, lockedUntil);
        }

        public async Task UpdatePasswordAsync(long adminUserId, string newPasswordHash, CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();
            const string sql = """
                UPDATE dbo.ADMIN_USERS
                SET PASSWORD_HASH = @PasswordHash,
                    PASSWORD_CHANGED_AT = SYSUTCDATETIME(),
                    UPDATED_AT = SYSUTCDATETIME()
                WHERE ADMIN_USER_ID = @AdminUserId;
            """;

            await connection.ExecuteAsync(sql, new { AdminUserId = adminUserId, PasswordHash = newPasswordHash });
        }
    }
}
