namespace MeatDelivery.Application.DTOs.Auth
{
    public class LogoutRequestDto
    {
        public string CountryCode { get; set; } = string.Empty;
        public string MobileNumber { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
    }
}
