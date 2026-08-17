using System;

namespace MeatDelivery.Domain.Entities.Authentication
{
    public class AdminSession
    {
        public long AdminSessionId { get; set; }
        public long AdminUserId { get; set; }
        public string RefreshTokenHash { get; set; } = string.Empty;
        public string? DeviceId { get; set; }
        public string? IpAddress { get; set; }
        public string? UserAgent { get; set; }
        public bool IsActive { get; set; } = true;
        public DateTime ExpiresAt { get; set; }
        public DateTime? LastActivityAt { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}
