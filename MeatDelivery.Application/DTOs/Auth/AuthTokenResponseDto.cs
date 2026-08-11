using System;
using System.Collections.Generic;

namespace MeatDelivery.Application.DTOs.Auth
{
    public class AuthTokenResponseDto
    {
        public long UserId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string CountryCode { get; set; } = string.Empty;
        public string MobileNumber { get; set; } = string.Empty;
        public bool IsNewUser { get; set; }
        public List<string> Roles { get; set; } = new();
        public string AccessToken { get; set; } = string.Empty;
        public DateTime AccessTokenExpiresAt { get; set; }
        public string RefreshToken { get; set; } = string.Empty;
        public DateTime RefreshTokenExpiresAt { get; set; }
    }
}
