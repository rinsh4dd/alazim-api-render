using System;
using System.Collections.Generic;
using System.Text;

namespace MeatDelivery.Application.Interfaces.Authentication
{
    public interface IPermissionService
    {
        Task<IList<string>> GetUserPermissionsAsync(
            long userId,
            CancellationToken cancellationToken = default);

        Task<IList<string>> GetUserRolesAsync(
            long userId,
            CancellationToken cancellationToken = default);

        Task<bool> HasPermissionAsync(
            long userId,
            string permission,
            CancellationToken cancellationToken = default);
    }
}
