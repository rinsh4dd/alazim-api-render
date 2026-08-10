using System;
using System.Collections.Generic;
using System.Text;

namespace MeatDelivery.Application.Interfaces.Repositories.Authentication
{
    public interface IPermissionRepository
    {
        Task<IReadOnlyList<string>> GetPermissionsAsync(
            Guid roleId,
            CancellationToken cancellationToken = default);
    }
}
