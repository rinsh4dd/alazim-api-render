using System;

namespace MeatDelivery.Application.DTOs.Auth
{
    public sealed class CreateUserDto
    {
        public string Username { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string? LastName { get; set; }
        public string? PhoneNumber { get; set; }
        public Guid RoleId { get; set; }
    }
}
