using System;

namespace MeatDelivery.Application.DTOs.Customization
{
    public class TemplateGroupMappingDto
    {
        public long TemplateGroupMappingId { get; set; }
        public long CustomizationTemplateId { get; set; }
        public string? TemplateNameEn { get; set; }
        public string? TemplateNameAr { get; set; }
        public long CustomizationGroupId { get; set; }
        public string GroupCode { get; set; } = string.Empty;
        public string GroupNameEn { get; set; } = string.Empty;
        public string GroupNameAr { get; set; } = string.Empty;
        public bool IsAdditionalPriceAvailable { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}
