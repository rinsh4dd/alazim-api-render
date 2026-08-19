using System;

namespace MeatDelivery.Application.DTOs.Product
{
    public class ProductDto
    {
        public long ProductId { get; set; }
        public long CategoryId { get; set; }
        public string? CategoryNameEn { get; set; }
        public string? CategoryNameAr { get; set; }
        public string DocNo { get; set; } = string.Empty;
        public string DocType { get; set; } = "PROD";
        public string ProductNameEn { get; set; } = string.Empty;
        public string ProductNameAr { get; set; } = string.Empty;
        public string? DescriptionEn { get; set; }
        public string? DescriptionAr { get; set; }
        public bool IsCustomizable { get; set; }
        public long? CustomizationTemplateId { get; set; }
        public int UnitId { get; set; }
        public string? UnitCode { get; set; }
        public string? UnitDescription { get; set; }
        public decimal DiscountPercentage { get; set; }
        public decimal StockCount { get; set; }
        public decimal Price { get; set; }
        public decimal SellingPrice { get; set; }
        public string? PrimaryUrl { get; set; }
        public string? SecondaryUrl { get; set; }
        public string? TertiaryUrl { get; set; }
        public bool IsFeatured { get; set; }
        public bool IsActive { get; set; }
        public bool IsDeleted { get; set; }
        public DateTime? DeletedAt { get; set; }
        public bool IsNewArrival { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}
