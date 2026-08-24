using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Customization
{
    public class SaveCustomizationGroupDto
    {
        public Mode Mode { get; set; }
        public long? CustomizationGroupId { get; set; }
        public string? GroupCode { get; set; }
        public string? GroupNameEn { get; set; }
        public string? GroupNameAr { get; set; }
        public bool IsAdditionalPriceAvailable { get; set; } = false;
        public bool IsActive { get; set; } = true;
    }
}
