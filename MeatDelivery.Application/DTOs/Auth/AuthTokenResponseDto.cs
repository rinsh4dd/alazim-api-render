using System;

namespace MeatDelivery.Application.DTOs.Auth
{
    public class AuthTokenResponseDto
    {
        public long UserId { get; set; }
        public string? DocType { get; set; }
        public string? DocNo { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string CountryCode { get; set; } = string.Empty;
        public string MobileNumber { get; set; } = string.Empty;
        public bool EligibleForOrder { get; set; }
        public bool IsProfileCompleted { get; set; }
        public bool IsNewUser { get; set; }
        public string AccessToken { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
    }
}
