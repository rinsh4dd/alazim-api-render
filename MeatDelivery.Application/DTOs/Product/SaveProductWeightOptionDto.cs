namespace MeatDelivery.Application.DTOs.Product
{
    public class SaveProductWeightOptionDto
    {
        public long? ProductWeightOptionId { get; set; }
        public int UnitId { get; set; }
        public decimal? UnitValue { get; set; }
        public bool IsCustomWeight { get; set; }
        public decimal? MinWeight { get; set; }
        public decimal? MaxWeight { get; set; }
        public decimal MinOrderQuantity { get; set; } = 1.0m;
        public decimal? MaxOrderQuantity { get; set; }
        public decimal QuantityIncrement { get; set; } = 1.0m;
        public bool IsDefault { get; set; }
        public int DisplayOrder { get; set; }
        public bool IsActive { get; set; } = true;

        // Pricing associated with weight option
        public string PriceType { get; set; } = "FIXED"; // 'FIXED' or 'PER_UNIT'
        public decimal RegularPrice { get; set; }
        public decimal? DiscountPrice { get; set; }
        public string CurrencyCode { get; set; } = "AED";
    }
}
