using System;
using System.Collections.Generic;
using System.Text;

namespace MeatDelivery.Application.DTOs.Auth
{
    public sealed class RefreshTokenRequestDto
    {
        public string AccessToken { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
    }
}
