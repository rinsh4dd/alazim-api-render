namespace MeatDelivery.Domain.Entities.Authentication
{
    public class UserRole
    {
        public long UserRoleId { get; set; }
        public long UserId { get; set; }
        public int RoleId { get; set; }
        public bool IsActive { get; set; } = true;
        public DateTime AssignedAt { get; set; } = DateTime.UtcNow;
        public long? AssignedByUserId { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}
