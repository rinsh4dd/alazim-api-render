namespace MeatDelivery.Application.DTOs.Auth
{
    public class RefreshTokenRequestDto
    {
        public string CountryCode { get; set; } = string.Empty;
        public string MobileNumber { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
        public string? DeviceId { get; set; }
        public string? DeviceType { get; set; }
    }
}
