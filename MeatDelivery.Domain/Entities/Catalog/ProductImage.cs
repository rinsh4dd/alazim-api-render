using System;

namespace MeatDelivery.Domain.Entities.Catalog
{
    public class ProductImage
    {
        public long ProductImageId { get; set; }
        public long ProductId { get; set; }
        public string ImageUrl { get; set; } = string.Empty;
        public bool IsPrimary { get; set; }
        public int DisplayOrder { get; set; }
        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}
