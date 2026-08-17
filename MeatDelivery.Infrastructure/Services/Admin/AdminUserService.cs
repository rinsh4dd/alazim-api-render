using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentValidation;
using MeatDelivery.Application.Common.Security;
using MeatDelivery.Application.DTOs.Admin;
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

            if (request.Mode == AdminUserMode.ADD && !string.IsNullOrWhiteSpace(request.Password))
            {
                passwordHash = _passwordHasher.Hash(request.Password);
            }
            else if (request.Mode == AdminUserMode.EDIT && !string.IsNullOrWhiteSpace(request.Password))
            {
                passwordHash = _passwordHasher.Hash(request.Password);
            }

            string? rolesCsv = request.Roles != null && request.Roles.Count > 0
                ? string.Join(",", request.Roles.Distinct().Select(r => r.Trim().ToUpperInvariant()))
                : null;

            try
            {
                var result = await _adminUserRepository.SaveAdminUserAsync(
                    request,
                    passwordHash,
                    rolesCsv,
                    currentAdminUserId,
                    cancellationToken);

                if (result == null)
                {
                    return ApiResponse<SaveAdminUserResponseDto>.FailureResponse("Failed to process admin user request.");
                }

                string message = request.Mode switch
                {
                    AdminUserMode.ADD => "Admin user created successfully.",
                    AdminUserMode.EDIT => "Admin user updated successfully.",
                    AdminUserMode.DELETE => "Admin user deleted successfully.",
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
                var (users, totalCount) = await _adminUserRepository.GetAdminUsersAsync(query, cancellationToken);

                return ApiResponse<List<SaveAdminUserResponseDto>>.SuccessResponse(
                    users,
                    "Admin users retrieved successfully.");
            }
            catch (Exception ex)
            {
                return ApiResponse<List<SaveAdminUserResponseDto>>.FailureResponse(ex.Message);
            }
        }

        public async Task<ApiResponse<SaveAdminUserResponseDto>> GetAdminUserByIdAsync(
            long adminUserId,
            CancellationToken cancellationToken = default)
        {
            try
            {
                var (user, roles) = await _adminUserRepository.GetByIdWithRolesAsync(adminUserId, cancellationToken);

                if (user == null)
                {
                    return ApiResponse<SaveAdminUserResponseDto>.FailureResponse(
                        "Admin user not found.",
                        status: 0);
                }

                var dto = new SaveAdminUserResponseDto
                {
                    AdminUserId = user.AdminUserId,
                    DocType = user.DocType,
                    DocNo = user.DocNo,
                    Email = user.Email,
                    FirstName = user.FirstName,
                    LastName = user.LastName ?? string.Empty,
                    FullName = user.FullName,
                    CountryCode = user.CountryCode,
                    MobileNumber = user.MobileNumber,
                    ProfileImageUrl = user.ProfileImageUrl,
                    AdminStatus = user.AdminStatus.ToString(),
                    IsDeleted = user.IsDeleted,
                    DeletedAt = user.DeletedAt,
                    Roles = roles,
                    CreatedAt = user.CreatedAt,
                    UpdatedAt = user.UpdatedAt
                };

                return ApiResponse<SaveAdminUserResponseDto>.SuccessResponse(dto, "Admin user details retrieved successfully.");
            }
            catch (Exception ex)
            {
                return ApiResponse<SaveAdminUserResponseDto>.FailureResponse(ex.Message);
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
    }
}
