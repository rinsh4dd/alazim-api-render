using System;
using System.Collections.Generic;
using System.Text;

namespace MeatDelivery.Application.DTOs.Auth
{
    public sealed class UserLoginDto
    {
        public Guid UserId { get; set; }

        public string Username { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public string PasswordHash { get; set; } = string.Empty;

        public bool IsActive { get; set; }

        public bool IsLocked { get; set; }

        public int FailedLoginAttempts { get; set; }

        public DateTime? LockoutEndUtc { get; set; }
    }
}
