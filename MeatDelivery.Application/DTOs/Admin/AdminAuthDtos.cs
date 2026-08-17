using System;
using System.Collections.Generic;

namespace MeatDelivery.Application.DTOs.Admin
{
    public class AdminLoginRequestDto
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }

    public class AdminRefreshTokenRequestDto
    {
        public string RefreshToken { get; set; } = string.Empty;
    }

    public class AdminAuthResponseDto
    {
        public long AdminUserId { get; set; }
        public string? DocType { get; set; }
        public string? DocNo { get; set; }
        public string Email { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public List<string> Roles { get; set; } = new();
        public string AccessToken { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
        public int ExpiresIn { get; set; }
    }

    public class AdminProfileDto
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
        public List<string> Roles { get; set; } = new();
        public DateTime? LastLoginAt { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class ChangeAdminPasswordRequestDto
    {
        public string CurrentPassword { get; set; } = string.Empty;
        public string NewPassword { get; set; } = string.Empty;
    }
}
