using System;

namespace MeatDelivery.Domain.Entities.Catalog
{
    public class CustomerWishlist
    {
        public long WishlistId { get; set; }
        public long CustomerUserId { get; set; }
        public long ProductId { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
