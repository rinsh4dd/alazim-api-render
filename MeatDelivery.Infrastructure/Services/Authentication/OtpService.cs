using MeatDelivery.Application.Interfaces.Authentication;
using System.Security.Cryptography;
using System.Text;

namespace MeatDelivery.Infrastructure.Services.Authentication
{
    public class OtpService : IOtpService
    {
        private const string OtpSaltSecret = "MeatDeliveryApp_Secure_OTP_Salt_2026";

        public string GenerateOtpCode()
        {
            int randomNumber = RandomNumberGenerator.GetInt32(1000, 9999);
            return randomNumber.ToString();
        }

        public string HashOtpCode(string otpCode, string countryCode, string mobileNumber)
        {
            string rawValue = $"{countryCode}:{mobileNumber}:{otpCode}:{OtpSaltSecret}";
            using var sha256 = SHA256.Create();
            byte[] bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(rawValue));
            return Convert.ToBase64String(bytes);
        }

        public bool VerifyOtpCode(string inputOtpCode, string storedOtpHash, string countryCode, string mobileNumber)
        {
            string computedHash = HashOtpCode(inputOtpCode, countryCode, mobileNumber);
            return CryptographicOperations.FixedTimeEquals(
                Encoding.UTF8.GetBytes(computedHash),
                Encoding.UTF8.GetBytes(storedOtpHash)
            );
        }
    }
}
