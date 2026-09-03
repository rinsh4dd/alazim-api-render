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
        public PricingType PricingType { get; set; } = PricingType.ADDITIONAL_PRICE;
        public bool IsCustomDataAllowed { get; set; } = false;
        public bool IsActive { get; set; } = true;
    }
}
