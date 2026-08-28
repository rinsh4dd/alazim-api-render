using System.Collections.Generic;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Customization
{
    public class SaveTemplateGroupMappingDto
    {
        public Mode Mode { get; set; } = Mode.ADD;
        public long CustomizationTemplateId { get; set; }
        public List<long> GroupIds { get; set; } = new List<long>();
        public bool IsActive { get; set; } = true;
    }
}
