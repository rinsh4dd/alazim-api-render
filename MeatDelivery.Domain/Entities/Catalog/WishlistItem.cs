using System;

namespace MeatDelivery.Domain.Entities.Catalog
{
    public class WishlistItem
    {
        public long WishlistItemId { get; set; }
        public long WishlistId { get; set; }
        public long ProductId { get; set; }
        public DateTime AddedAt { get; set; } = DateTime.UtcNow;

        public Product? Product { get; set; }
    }
}
