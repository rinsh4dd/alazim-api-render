
using MeatDelivery.Domain.Enums;


namespace MeatDelivery.Application.DTOs.Role
{
    public class SaveAdminRoleDto
    {
        public Mode Mode { get; set; } = Mode.ADD;
        public int? RoleId { get; set; }
        public string? RoleCode { get; set; }
        public string? RoleName { get; set; }
        public string? Description { get; set; }
        public bool? IsActive { get; set; }
    }
}