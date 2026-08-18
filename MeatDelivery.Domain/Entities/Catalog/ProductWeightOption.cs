using System;

namespace MeatDelivery.Domain.Entities.Catalog
{
    public class ProductWeightOption
    {
        public long ProductWeightOptionId { get; set; }
        public long ProductId { get; set; }
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
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}
