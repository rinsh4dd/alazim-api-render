using System;
using System.Collections.Generic;

namespace MeatDelivery.Application.DTOs.Customization
{
    public class ProductCustomizationHierarchyDto
    {
        public long ProductId { get; set; }
        public string? ProductNameEn { get; set; }
        public string? ProductNameAr { get; set; }
        public bool IsCustomizable { get; set; }
        public long? CustomizationTemplateId { get; set; }

        public CustomizationTemplateHierarchyDto? Template { get; set; }
    }

    public class CustomizationTemplateHierarchyDto
    {
        public long CustomizationTemplateId { get; set; }
        public string DocNo { get; set; } = string.Empty;
        public string TemplateNameEn { get; set; } = string.Empty;
        public string TemplateNameAr { get; set; } = string.Empty;
        public string? DescriptionEn { get; set; }
        public string? DescriptionAr { get; set; }
        public bool IsActive { get; set; }

        public List<CustomizationGroupHierarchyDto> Groups { get; set; } = new();
    }

    public class CustomizationGroupHierarchyDto
    {
        public long CustomizationGroupId { get; set; }
        public string GroupCode { get; set; } = string.Empty;
        public string GroupNameEn { get; set; } = string.Empty;
        public string GroupNameAr { get; set; } = string.Empty;
        public bool IsAdditionalPriceAvailable { get; set; }
        public bool IsActive { get; set; }

        public List<CustomizationOptionHierarchyDto> Options { get; set; } = new();
    }

    public class CustomizationOptionHierarchyDto
    {
        public long CustomizationOptionId { get; set; }
        public long CustomizationGroupId { get; set; }
        public string OptionCode { get; set; } = string.Empty;
        public string OptionNameEn { get; set; } = string.Empty;
        public string OptionNameAr { get; set; } = string.Empty;
        public decimal AdditionalPrice { get; set; }
        public bool IsActive { get; set; }
    }
}
