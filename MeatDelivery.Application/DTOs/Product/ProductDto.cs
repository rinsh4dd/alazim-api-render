using System;
using System.Collections.Generic;

namespace MeatDelivery.Application.DTOs.Product
{
    public class ProductDto
    {
        public long ProductId { get; set; }
        public long CategoryId { get; set; }
        public string? CategoryNameEn { get; set; }
        public string DocNo { get; set; } = string.Empty;
        public string DocType { get; set; } = "PRD1";
        public string ProductNameEn { get; set; } = string.Empty;
        public string ProductNameAr { get; set; } = string.Empty;
        public string? DescriptionEn { get; set; }
        public string? DescriptionAr { get; set; }
        public string? CountryOfOrigin { get; set; }
        public bool IsHalalCertified { get; set; }
        public string? HalalCertificateNo { get; set; }
        public string? HalalCertificateUrl { get; set; }
        public string? NutritionInformationEn { get; set; }
        public string? NutritionInformationAr { get; set; }
        public string? StorageInstructionsEn { get; set; }
        public string? StorageInstructionsAr { get; set; }
        public bool IsCustomizable { get; set; }
        public long? CustomizationTemplateId { get; set; }
        public int DisplayOrder { get; set; }
        public bool IsFeatured { get; set; }
        public bool IsBestseller { get; set; }
        public bool IsActive { get; set; }
        public bool IsDeleted { get; set; }
        public DateTime? DeletedAt { get; set; }
        public bool IsWishlisted { get; set; }
        public bool IsRecentlyOrdered { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }

        public List<ProductWeightOptionDto> WeightOptions { get; set; } = new();
        public List<ProductImageDto> Images { get; set; } = new();
    }
}
