using System;

namespace MeatDelivery.Application.DTOs.Customization
{
    public class CustomizationOptionDto
    {
        public long CustomizationOptionId { get; set; }
        public long CustomizationGroupId { get; set; }
        public string? GroupNameEn { get; set; }
        public string? GroupNameAr { get; set; }
        public string OptionCode { get; set; } = string.Empty;
        public string OptionNameEn { get; set; } = string.Empty;
        public string OptionNameAr { get; set; } = string.Empty;
        public decimal AdditionalPrice { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}
