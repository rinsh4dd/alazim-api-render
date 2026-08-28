using System;
using System.Collections.Generic;

namespace MeatDelivery.Application.DTOs.Customization
{
    public class CustomizationGroupDto
    {
        public long CustomizationGroupId { get; set; }
        public string GroupCode { get; set; } = string.Empty;
        public string GroupNameEn { get; set; } = string.Empty;
        public string GroupNameAr { get; set; } = string.Empty;
        public bool IsAdditionalPriceAvailable { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        public List<CustomizationOptionDto> Options { get; set; } = new();
    }
}
