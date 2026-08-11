namespace MeatDelivery.Domain.Entities.Authentication
{
    public class UserSession
    {
        public long SessionId { get; set; }
        public long UserId { get; set; }
        public string RefreshTokenHash { get; set; } = string.Empty;
        public string? DeviceId { get; set; }
        public string? DeviceType { get; set; }
        public string? IpAddress { get; set; }
        public bool IsActive { get; set; } = true;
        public DateTime ExpiresAt { get; set; }
        public DateTime? LastActivityAt { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}
