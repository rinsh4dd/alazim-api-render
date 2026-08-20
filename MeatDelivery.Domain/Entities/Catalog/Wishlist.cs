using System;
using System.Collections.Generic;

namespace MeatDelivery.Domain.Entities.Catalog
{
    public class Wishlist
    {
        public long WishlistId { get; set; }
        public long CustomerUserId { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }

        public ICollection<WishlistItem> Items { get; set; } = new List<WishlistItem>();
    }
}
