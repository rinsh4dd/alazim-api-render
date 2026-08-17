using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentValidation;
using MeatDelivery.Application.Common.Security;
using MeatDelivery.Application.DTOs.Admin;
using MeatDelivery.Application.DTOs.Role;
using MeatDelivery.Application.Interfaces.Admin;
using MeatDelivery.Application.Interfaces.Repositories.Authentication;
using MeatDelivery.Domain.Enums;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Infrastructure.Services.Admin
{
    public class AdminUserService : IAdminUserService
    {
        private readonly IAdminUserRepository _adminUserRepository;
        private readonly IPasswordHasher _passwordHasher;
        private readonly IValidator<SaveAdminUserDto> _saveAdminUserValidator;

        public AdminUserService(
            IAdminUserRepository adminUserRepository,
            IPasswordHasher passwordHasher,
            IValidator<SaveAdminUserDto> saveAdminUserValidator)
        {
            _adminUserRepository = adminUserRepository;
            _passwordHasher = passwordHasher;
            _saveAdminUserValidator = saveAdminUserValidator;
        }

        public async Task<ApiResponse<SaveAdminUserResponseDto>> SaveAdminUserAsync(
            SaveAdminUserDto request,
            long currentAdminUserId,
            CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(request);

            var validationResult = await _saveAdminUserValidator.ValidateAsync(request, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errorMessages = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<SaveAdminUserResponseDto>.FailureResponse(
                    "Validation failed.",
                    errorMessages);
            }

            string? passwordHash = null;

            if (request.Mode == Mode.ADD && !string.IsNullOrWhiteSpace(request.Password))
            {
                passwordHash = _passwordHasher.Hash(request.Password);
            }
            else if (request.Mode == Mode.EDIT && !string.IsNullOrWhiteSpace(request.Password))
            {
                passwordHash = _passwordHasher.Hash(request.Password);
            }

            try
            {
                var result = await _adminUserRepository.SaveAdminUserAsync(
                    request,
                    passwordHash,
                    currentAdminUserId,
                    cancellationToken);

                if (result == null)
                {
                    return ApiResponse<SaveAdminUserResponseDto>.FailureResponse("Failed to process admin user request.");
                }

                string message = request.Mode switch
                {
                    Mode.ADD => "Admin user created successfully.",
                    Mode.EDIT => "Admin user updated successfully.",
                    Mode.DELETE => "Admin user deleted successfully.",
                    _ => "Operation completed successfully."
                };

                return ApiResponse<SaveAdminUserResponseDto>.SuccessResponse(result, message);
            }
            catch (Exception ex)
            {
                return ApiResponse<SaveAdminUserResponseDto>.FailureResponse(ex.Message);
            }
        }

        public async Task<ApiResponse<List<SaveAdminUserResponseDto>>> GetAdminUsersAsync(
            GetAdminUsersQueryDto query,
            CancellationToken cancellationToken = default)
        {
            try
            {
                query ??= new GetAdminUsersQueryDto();
                var users = await _adminUserRepository.GetAdminUsersAsync(query, cancellationToken);

                string message = (query.AdminUserId.HasValue && query.AdminUserId.Value > 0)
                    ? (users.Count > 0 ? "Admin user retrieved successfully." : "Admin user not found.")
                    : "Admin users retrieved successfully.";

                return ApiResponse<List<SaveAdminUserResponseDto>>.SuccessResponse(
                    users,
                    message: message);
            }
            catch (Exception ex)
            {
                return ApiResponse<List<SaveAdminUserResponseDto>>.FailureResponse(ex.Message);
            }
        }

        public async Task<ApiResponse<List<AdminRoleDto>>> GetAdminRolesAsync(CancellationToken cancellationToken = default)
        {
            try
            {
                var roles = await _adminUserRepository.GetAdminRolesAsync(cancellationToken);
                return ApiResponse<List<AdminRoleDto>>.SuccessResponse(roles, "Admin roles retrieved successfully.");
            }
            catch (Exception ex)
            {
                return ApiResponse<List<AdminRoleDto>>.FailureResponse(ex.Message);
            }
        }
        public async Task<ApiResponse<AdminRoleDto>> SaveAdminRoleAsync(SaveAdminRoleDto request,CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(request);

            try
            {
                var result = await _adminUserRepository.SaveAdminRoleAsync(request,cancellationToken);

                if (result == null)
                {
                    return ApiResponse<AdminRoleDto>.FailureResponse("Failed to process admin role request.");
                }

                string message = request.Mode switch
                {
                    Mode.ADD => "Admin role created successfully.",
                    Mode.EDIT => "Admin role updated successfully.",
                    Mode.DELETE => "Admin role deleted successfully.",
                    _ => "Operation completed successfully."
                };

                return ApiResponse<AdminRoleDto>.SuccessResponse(result,message);
            }
            catch (Exception ex)
            {
                return ApiResponse<AdminRoleDto>.FailureResponse(ex.Message);
            }
        }
    }
}
