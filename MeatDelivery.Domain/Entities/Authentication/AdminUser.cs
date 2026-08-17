using System;
using System.Linq;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Domain.Entities.Authentication
{
    public class AdminUser
    {
        public long AdminUserId { get; set; }
        public string? DocType { get; set; }
        public string? DocNo { get; set; }
        public string Email { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string? LastName { get; set; }
        public string FullName => string.Join(" ", new[] { FirstName, LastName }.Where(s => !string.IsNullOrWhiteSpace(s))).Trim();
        public string? CountryCode { get; set; }
        public string? MobileNumber { get; set; }
        public string? ProfileImageUrl { get; set; }
        public AdminStatus AdminStatus { get; set; } = AdminStatus.ACTIVE;
        public int FailedLoginCount { get; set; } = 0;
        public DateTime? LockedUntil { get; set; }
        public DateTime? LastLoginAt { get; set; }
        public DateTime? PasswordChangedAt { get; set; }
        public long? CreatedByAdminUserId { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}
