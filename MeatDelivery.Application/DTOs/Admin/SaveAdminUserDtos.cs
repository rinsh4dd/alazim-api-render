using System;
using System.Collections.Generic;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Admin
{
    public class SaveAdminUserDto
    {
        public AdminUserMode Mode { get; set; } = AdminUserMode.ADD;
        public long? AdminUserId { get; set; }
        public string? DocType { get; set; }
        public string? DocNo { get; set; }
        public string? Email { get; set; }
        public string? Password { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? CountryCode { get; set; }
        public string? MobileNumber { get; set; }
        public string? ProfileImageUrl { get; set; }
        public MeatDelivery.Domain.Enums.AdminStatus? AdminStatus { get; set; } = MeatDelivery.Domain.Enums.AdminStatus.ACTIVE;
        public List<string> Roles { get; set; } = new();
    }

    public class SaveAdminUserResponseDto
    {
        public long AdminUserId { get; set; }
        public string? DocType { get; set; }
        public string? DocNo { get; set; }
        public string Email { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string? CountryCode { get; set; }
        public string? MobileNumber { get; set; }
        public string? ProfileImageUrl { get; set; }
        public string AdminStatus { get; set; } = string.Empty;
        public bool IsDeleted { get; set; }
        public DateTime? DeletedAt { get; set; }
        public List<string> Roles { get; set; } = new();
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }

    public class GetAdminUsersQueryDto
    {
        public string? Search { get; set; }
        public string? Role { get; set; }
        public AdminStatus? Status { get; set; }
        public bool IncludeDeleted { get; set; } = false;
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 20;
    }

    public class AdminRoleDto
    {
        public int RoleId { get; set; }
        public string RoleCode { get; set; } = string.Empty;
        public string RoleName { get; set; } = string.Empty;
        public string? Description { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
