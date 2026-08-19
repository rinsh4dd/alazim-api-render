using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Product
{
    public class SaveProductDto
    {
        public Mode Mode { get; set; } = Mode.ADD;
        public long? ProductId { get; set; }
        public long CategoryId { get; set; }
        public string ProductNameEn { get; set; } = string.Empty;
        public string ProductNameAr { get; set; } = string.Empty;
        public string? DescriptionEn { get; set; }
        public string? DescriptionAr { get; set; }
        public bool IsCustomizable { get; set; }
        public long? CustomizationTemplateId { get; set; }
        public int UnitId { get; set; }
        public decimal DiscountPercentage { get; set; }
        public decimal InitialStockCount { get; set; }
        public decimal Price { get; set; }
        public string PrimaryUrl { get; set; } = string.Empty;
        public string? SecondaryUrl { get; set; }
        public string? TertiaryUrl { get; set; }
        public bool IsFeatured { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
