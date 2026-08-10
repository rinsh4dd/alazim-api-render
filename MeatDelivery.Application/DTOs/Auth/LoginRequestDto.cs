using System;
using System.Collections.Generic;
using System.Text;

namespace MeatDelivery.Application.DTOs.Auth
{
    public sealed class LoginRequestDto
    {
        public string UserNameOrEmail { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string? TenantCode { get; set; }
    }
}
