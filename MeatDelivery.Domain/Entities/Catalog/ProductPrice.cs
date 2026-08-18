using System;

namespace MeatDelivery.Domain.Entities.Catalog
{
    public class ProductPrice
    {
        public long ProductPriceId { get; set; }
        public long ProductId { get; set; }
        public long ProductWeightOptionId { get; set; }
        public string PriceType { get; set; } = "FIXED"; // 'FIXED' or 'PER_UNIT'
        public decimal RegularPrice { get; set; }
        public decimal? DiscountPrice { get; set; }
        public string CurrencyCode { get; set; } = "AED";
        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}
