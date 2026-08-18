using System;

namespace MeatDelivery.Domain.Entities.Catalog
{
    public class Product
    {
        public long ProductId { get; set; }
        public long CategoryId { get; set; }
        public string DocNo { get; set; } = string.Empty;
        public string DocType { get; set; } = "PRD1";
        public string ProductNameEn { get; set; } = string.Empty;
        public string ProductNameAr { get; set; } = string.Empty;
        public string? DescriptionEn { get; set; }
        public string? DescriptionAr { get; set; }
        public string? CountryOfOrigin { get; set; }
        public bool IsHalalCertified { get; set; } = true;
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
        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}
