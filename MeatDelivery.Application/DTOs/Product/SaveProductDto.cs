using System.Collections.Generic;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Product
{
    public class SaveProductDto
    {
        public Mode Mode { get; set; }

        public long? ProductId { get; set; }
        public long? CategoryId { get; set; }
        public string? DocNo { get; set; }
        public string? DocType { get; set; } = "PRD1";
        public string? ProductNameEn { get; set; }
        public string? ProductNameAr { get; set; }
        public string? DescriptionEn { get; set; }
        public string? DescriptionAr { get; set; }
        public string? CountryOfOrigin { get; set; }
        public bool? IsHalalCertified { get; set; } = true;
        public string? HalalCertificateNo { get; set; }
        public string? HalalCertificateUrl { get; set; }
        public string? NutritionInformationEn { get; set; }
        public string? NutritionInformationAr { get; set; }
        public string? StorageInstructionsEn { get; set; }
        public string? StorageInstructionsAr { get; set; }
        public bool? IsCustomizable { get; set; }
        public long? CustomizationTemplateId { get; set; }
        public int? DisplayOrder { get; set; }
        public bool? IsFeatured { get; set; }
        public bool? IsBestseller { get; set; }
        public bool? IsActive { get; set; }

        public List<SaveProductWeightOptionDto>? WeightOptions { get; set; }
        public List<SaveProductImageDto>? Images { get; set; }
    }
}
