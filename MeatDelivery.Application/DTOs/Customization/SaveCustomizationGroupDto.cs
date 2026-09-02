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
        public string? PricingType { get; set; } // ADDITIONAL_PRICE, MULTIPLIER, FIXED_PRICE, PERCENTAGE
        public decimal? PricingValue { get; set; }
        public bool IsCustomDataAllowed { get; set; } = false;
        public bool IsActive { get; set; } = true;
    }
}
