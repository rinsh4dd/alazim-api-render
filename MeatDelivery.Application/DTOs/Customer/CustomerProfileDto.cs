using System;

namespace MeatDelivery.Application.DTOs.Customer
{
    public class CustomerProfileDto
    {
        public long UserId { get; set; }
        public string? DocType { get; set; }
        public string? DocNo { get; set; }
        public string CountryCode { get; set; } = string.Empty;
        public string MobileNumber { get; set; } = string.Empty;
        public string? Email { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string FullName { get; set; } = string.Empty;
        public DateTime? Dob { get; set; }
        public string? Gender { get; set; }
        public string? ProfileImageUrl { get; set; }
        public string LanguageCode { get; set; } = "EN";
        public bool IsMobileVerified { get; set; }
        public bool IsEmailVerified { get; set; }
        public bool EligibleForOrder { get; set; }
        public bool IsProfileCompleted { get; set; }
        public string UserStatus { get; set; } = "PENDING";
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}
