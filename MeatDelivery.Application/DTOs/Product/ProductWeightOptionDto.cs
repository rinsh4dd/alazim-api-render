namespace MeatDelivery.Application.DTOs.Product
{
    public class ProductWeightOptionDto
    {
        public long ProductWeightOptionId { get; set; }
        public long ProductId { get; set; }
        public int UnitId { get; set; }
        public string? Unit { get; set; }
        public string? UnitDescription { get; set; }
        public decimal? UnitValue { get; set; }
        public bool IsCustomWeight { get; set; }
        public decimal? MinWeight { get; set; }
        public decimal? MaxWeight { get; set; }
        public decimal MinOrderQuantity { get; set; }
        public decimal? MaxOrderQuantity { get; set; }
        public decimal QuantityIncrement { get; set; }
        public bool IsDefault { get; set; }
        public int DisplayOrder { get; set; }
        public bool IsActive { get; set; }

        // Associated Price
        public long? ProductPriceId { get; set; }
        public string PriceType { get; set; } = "FIXED";
        public decimal RegularPrice { get; set; }
        public decimal? DiscountPrice { get; set; }
        public string CurrencyCode { get; set; } = "AED";
    }
}
