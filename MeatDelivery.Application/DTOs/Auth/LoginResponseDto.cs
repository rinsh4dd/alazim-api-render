using System;
using System.Collections.Generic;
using System.Text;

namespace MeatDelivery.Application.DTOs.Auth
{
    public sealed class LoginResponseDto
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public string AccessToken { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
        public DateTime ExpiresAtUtc { get; set; }
        public UserContextDto? User { get; set; }
    }
}
