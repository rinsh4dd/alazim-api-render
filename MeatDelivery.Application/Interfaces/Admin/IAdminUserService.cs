using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Admin;
using MeatDelivery.Application.DTOs.Role;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Admin
{
    public interface IAdminUserService
    {
        Task<ApiResponse<SaveAdminUserResponseDto>> SaveAdminUserAsync(
            SaveAdminUserDto request,
            long currentAdminUserId,
            CancellationToken cancellationToken = default);

        Task<ApiResponse<List<SaveAdminUserResponseDto>>> GetAdminUsersAsync(
            GetAdminUsersQueryDto query,
            CancellationToken cancellationToken = default);

        Task<ApiResponse<List<AdminRoleDto>>> GetAdminRolesAsync(
            CancellationToken cancellationToken = default);
        Task<ApiResponse<AdminRoleDto>> SaveAdminRoleAsync(SaveAdminRoleDto request, CancellationToken cancellationToken = default);
    }
}
