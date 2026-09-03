using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Customization
{
    public class SaveCustomizationOptionDto
    {
        public Mode Mode { get; set; }
        public long? CustomizationOptionId { get; set; }
        public long CustomizationGroupId { get; set; }
        public string OptionCode { get; set; } = string.Empty;
        public string OptionNameEn { get; set; } = string.Empty;
        public string OptionNameAr { get; set; } = string.Empty;
        public decimal PricingValue { get; set; } = 0.00m;
        public bool IsActive { get; set; } = true;
    }
}
