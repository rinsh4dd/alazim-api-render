using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Customization
{
    public class SaveCustomizationTemplateDto
    {
        public Mode Mode { get; set; }

        public long? CustomizationTemplateId { get; set; }

        public string? TemplateNameEn { get; set; }
        public string? TemplateNameAr { get; set; }

        public string? DescriptionEn { get; set; }
        public string? DescriptionAr { get; set; }

        public bool? IsActive { get; set; }
    }
}
