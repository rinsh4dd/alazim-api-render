namespace MeatDelivery.Domain.Entities.Authentication
{
    public class User
    {
        public long UserId { get; set; }
        public string CountryCode { get; set; } = string.Empty;
        public string MobileNumber { get; set; } = string.Empty;
        public string? Email { get; set; }
        public string? PasswordHash { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string? ProfileImageUrl { get; set; }
        public string? Designation { get; set; }
        public string LanguageCode { get; set; } = "EN";
        public bool IsMobileVerified { get; set; }
        public bool IsEmailVerified { get; set; }
        public bool IsProfileCompleted { get; set; }
        public string UserStatus { get; set; } = "PENDING";
        public DateTime? LastLoginAt { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}
