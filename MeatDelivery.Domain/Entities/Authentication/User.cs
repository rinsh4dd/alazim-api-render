using System;
using System.Linq;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Domain.Entities.Authentication
{
    public class User
    {
        public long UserId { get; set; }
        public string? DocType { get; set; }
        public string? DocNo { get; set; }
        public string CountryCode { get; set; } = string.Empty;
        public string MobileNumber { get; set; } = string.Empty;
        public string? Email { get; set; }
        public string? PasswordHash { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string FullName => string.Join(" ", new[] { FirstName, LastName }.Where(s => !string.IsNullOrWhiteSpace(s))).Trim();
        public DateTime? Dob { get; set; }
        public Gender? Gender { get; set; }
        public string? ProfileImageUrl { get; set; }
        public string LanguageCode { get; set; } = "EN";
        public bool IsMobileVerified { get; set; }
        public bool IsEmailVerified { get; set; }
        public bool EligibleForOrder { get; set; }
        public bool IsProfileCompleted { get; set; }
        public UserStatus UserStatus { get; set; } = UserStatus.PENDING;
        public DateTime? LastLoginAt { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}
