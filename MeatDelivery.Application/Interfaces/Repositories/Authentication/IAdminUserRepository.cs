using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Domain.Entities.Authentication;

namespace MeatDelivery.Application.Interfaces.Repositories.Authentication
{
    public interface IAdminUserRepository
    {
        Task<(AdminUser? User, List<string> Roles)> GetByEmailWithRolesAsync(string email, CancellationToken cancellationToken = default);
        Task<(AdminUser? User, List<string> Roles)> GetByIdWithRolesAsync(long adminUserId, CancellationToken cancellationToken = default);
        Task RecordLoginSuccessAsync(long adminUserId, string? upgradedPasswordHash = null, CancellationToken cancellationToken = default);
        Task<(int FailedCount, DateTime? LockedUntil)> RecordLoginFailureAsync(long adminUserId, int maxAttempts = 5, int lockoutMinutes = 15, CancellationToken cancellationToken = default);
        Task UpdatePasswordAsync(long adminUserId, string newPasswordHash, CancellationToken cancellationToken = default);
    }
}
