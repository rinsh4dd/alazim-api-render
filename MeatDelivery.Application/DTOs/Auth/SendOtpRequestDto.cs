namespace MeatDelivery.Application.DTOs.Auth
{
    public class SendOtpRequestDto
    {
        public string CountryCode { get; set; } = string.Empty;
        public string MobileNumber { get; set; } = string.Empty;
    }
}
