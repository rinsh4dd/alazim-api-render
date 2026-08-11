namespace MeatDelivery.Application.DTOs.Auth
{
    public class VerifyOtpRequestDto
    {
        public Guid? ChallengeId { get; set; }
        public string CountryCode { get; set; } = string.Empty;
        public string MobileNumber { get; set; } = string.Empty;
        public string OtpCode { get; set; } = string.Empty;
    }
}
