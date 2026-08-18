using System;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Admin
{
    public class SaveAdminUserDto
    {
        public Mode Mode { get; set; } = Mode.ADD;
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
        public string? Nationality { get; set; }
        public DateTime? Dob { get; set; }
        public string? Address { get; set; }
        public string? AdminStatus { get; set; } = "ACTIVE";
        public int? RoleId { get; set; }
    }

    public class SaveAdminUserResponseDto
    {
        public long AdminUserId { get; set; }
        public string? DocType { get; set; }
        public string? DocNo { get; set; }
        public string Email { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string? CountryCode { get; set; }
        public string? MobileNumber { get; set; }
        public string? ProfileImageUrl { get; set; }
        public string? Nationality { get; set; }
        public DateTime? Dob { get; set; }
        public string? Address { get; set; }
        public string AdminStatus { get; set; } = string.Empty;
        public bool IsDeleted { get; set; }
        public DateTime? DeletedAt { get; set; }
        public int? RoleId { get; set; }
        public string Role { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }

    public class GetAdminUsersQueryDto
    {
        public long? AdminUserId { get; set; }
        public int? RoleId { get; set; }
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
