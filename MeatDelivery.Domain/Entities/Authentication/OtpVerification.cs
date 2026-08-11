namespace MeatDelivery.Domain.Entities.Authentication
{
    public class OtpVerification
    {
        public long OtpId { get; set; }
        public long? UserId { get; set; }
        public string CountryCode { get; set; } = string.Empty;
        public string MobileNumber { get; set; } = string.Empty;
        public string OtpHash { get; set; } = string.Empty;
        public string OtpPurpose { get; set; } = string.Empty;
        public int AttemptCount { get; set; }
        public int ResendCount { get; set; }
        public int MaxAttempts { get; set; } = 5;
        public string OtpStatus { get; set; } = "PENDING";
        public DateTime ExpiresAt { get; set; }
        public DateTime? VerifiedAt { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}
