using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Dapper;
using MeatDelivery.Application.DTOs.Admin;
using MeatDelivery.Application.DTOs.Role;
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

        public async Task<SaveAdminUserResponseDto?> SaveAdminUserAsync(
            MeatDelivery.Application.DTOs.Admin.SaveAdminUserDto request,
            string? passwordHash,
            long? actionedByAdminId,
            CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();
            var row = await connection.QuerySingleOrDefaultAsync<dynamic>(
                "dbo.PR_SAVE_ADMIN_USER",
                new
                {
                    MODE = request.Mode.ToString(),
                    ADMIN_USER_ID = request.AdminUserId,
                    EMAIL = request.Email,
                    PASSWORD_HASH = passwordHash,
                    FIRST_NAME = request.FirstName,
                    LAST_NAME = request.LastName,
                    COUNTRY_CODE = request.CountryCode,
                    MOBILE_NUMBER = request.MobileNumber,
                    PROFILE_IMAGE_URL = request.ProfileImageUrl,
                    ADMIN_STATUS = request.AdminStatus ?? "ACTIVE",
                    ROLE_ID = request.RoleId,
                    ACTIONED_BY_ADMIN_ID = actionedByAdminId
                },
                commandType: CommandType.StoredProcedure);

            if (row == null) return null;

            return new SaveAdminUserResponseDto
            {
                AdminUserId = (long)row.ADMIN_USER_ID,
                DocType = (string?)row.DOCTYPE,
                DocNo = (string?)row.DOC_NO,
                Email = (string)row.EMAIL,
                FirstName = (string)row.FIRST_NAME,
                LastName = (string?)row.LAST_NAME ?? string.Empty,
                FullName = $"{row.FIRST_NAME} {row.LAST_NAME}".Trim(),
                CountryCode = (string?)row.COUNTRY_CODE,
                MobileNumber = (string?)row.MOBILE_NUMBER,
                ProfileImageUrl = (string?)row.PROFILE_IMAGE_URL,
                AdminStatus = (string)row.ADMIN_STATUS,
                IsDeleted = (bool)row.IS_DELETED,
                DeletedAt = (DateTime?)row.DELETED_AT,
                Role = (string?)row.ROLE ?? string.Empty,
                CreatedAt = (DateTime)row.CREATED_AT,
                UpdatedAt = (DateTime?)row.UPDATED_AT
            };
        }

        public async Task<List<SaveAdminUserResponseDto>> GetAdminUsersAsync(
            MeatDelivery.Application.DTOs.Admin.GetAdminUsersQueryDto query,
            CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();
            var rows = (await connection.QueryAsync<dynamic>(
                "dbo.PR_GET_ADMIN_USERS",
                new
                {
                    ADMIN_USER_ID = query.AdminUserId,
                    ROLE_CODE = (string?)null
                },
                commandType: CommandType.StoredProcedure)).ToList();

            var list = new List<SaveAdminUserResponseDto>();

            foreach (var row in rows)
            {
                list.Add(new SaveAdminUserResponseDto
                {
                    AdminUserId = (long)row.ADMIN_USER_ID,
                    DocType = (string?)row.DOCTYPE,
                    DocNo = (string?)row.DOC_NO,
                    Email = (string)row.EMAIL,
                    FirstName = (string)row.FIRST_NAME,
                    LastName = (string?)row.LAST_NAME ?? string.Empty,
                    FullName = $"{row.FIRST_NAME} {row.LAST_NAME}".Trim(),
                    CountryCode = (string?)row.COUNTRY_CODE,
                    MobileNumber = (string?)row.MOBILE_NUMBER,
                    ProfileImageUrl = (string?)row.PROFILE_IMAGE_URL,
                    AdminStatus = (string)row.ADMIN_STATUS,
                    IsDeleted = (bool)row.IS_DELETED,
                    DeletedAt = (DateTime?)row.DELETED_AT,
                    Role = (string?)row.ROLE ?? string.Empty,
                    CreatedAt = (DateTime)row.CREATED_AT,
                    UpdatedAt = (DateTime?)row.UPDATED_AT
                });
            }

            return list;
        }

        public async Task<List<AdminRoleDto>> GetAdminRolesAsync(
    CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();

            var rows = await connection.QueryAsync<AdminRoleDto>(
                "dbo.PR_GET_ADMIN_ROLES",
                commandType: CommandType.StoredProcedure);

            return rows.ToList();
        }
         public async Task<AdminRoleDto?> SaveAdminRoleAsync(
            SaveAdminRoleDto request,
            CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();

            var result = await connection.QuerySingleOrDefaultAsync<AdminRoleDto>(
                "dbo.PR_SAVE_ADMIN_ROLE",
                new
                {
                    MODE = request.Mode.ToString(),
                    ROLE_ID = request.RoleId,
                    ROLE_CODE = request.RoleCode,
                    ROLE_NAME = request.RoleName,
                    DESCRIPTION = request.Description,
                    IS_ACTIVE = request.IsActive
                },
                commandType: CommandType.StoredProcedure);

            return result;
        }
    
    }
}
