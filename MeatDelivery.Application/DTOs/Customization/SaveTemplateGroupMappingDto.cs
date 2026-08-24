using System.Collections.Generic;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Customization
{
    public class SaveTemplateGroupMappingDto
    {
        public Mode Mode { get; set; } = Mode.ADD;
        public long? TemplateGroupMappingId { get; set; }
        public long CustomizationTemplateId { get; set; }
        public long? CustomizationGroupId { get; set; }

        // Optional list for bulk TVP mapping mode
        public List<long>? GroupIds { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
