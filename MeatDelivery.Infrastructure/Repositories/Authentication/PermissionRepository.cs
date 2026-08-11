using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Authentication;
using System;
using System.Collections.Generic;
using System.Text;

namespace MeatDelivery.Infrastructure.Repositories.Authentication
{
    public sealed class PermissionRepository : IPermissionRepository
    {
        private readonly IDapperRepository _repository;

        public PermissionRepository(IDapperRepository repository)
        {
            _repository = repository;
        }

        public async Task<IReadOnlyList<string>> GetPermissionsAsync(
            Guid roleId,
            CancellationToken cancellationToken = default)
        {
            var permissions = await _repository.QueryAsync<string>(
                "PR_AUTH_GET_ROLE_PERMISSIONS",
                new { RoleId = roleId });

            return permissions.ToList();
        }
    }
}
