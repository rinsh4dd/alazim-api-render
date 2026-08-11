namespace MeatDelivery.Application.Interfaces.Authentication
{
    public interface IOtpService
    {
        string GenerateOtpCode();
        string HashOtpCode(string otpCode, string countryCode, string mobileNumber);
        bool VerifyOtpCode(string inputOtpCode, string storedOtpHash, string countryCode, string mobileNumber);
    }
}
