using System;

namespace MeatDelivery.Application.DTOs.Customization
{
    public class CustomizationTemplateDto
    {
        public long CustomizationTemplateId { get; set; }
        public string DocNo { get; set; } = string.Empty;
        public string DocType { get; set; } = "CTP1";
        public string TemplateNameEn { get; set; } = string.Empty;
        public string TemplateNameAr { get; set; } = string.Empty;
        public string? DescriptionEn { get; set; }
        public string? DescriptionAr { get; set; }
        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}
