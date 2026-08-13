namespace MeatDelivery.Application.DTOs.Auth
{
    public class SendOtpResponseDto
    {
        public Guid ChallengeId { get; set; }
        public string CountryCode { get; set; } = string.Empty;
        public string MobileNumber { get; set; } = string.Empty;
        public DateTime ExpiresAt { get; set; }
        public int Interval { get; set; } = 60;
        public string? DevOtpCode { get; set; }
    }
}
