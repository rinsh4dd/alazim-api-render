using System;

namespace MeatDelivery.Application.DTOs.Wishlist
{
    public class WishlistToggleResponseDto
    {
        public long WishlistId { get; set; }
        public long CustomerUserId { get; set; }
        public long ProductId { get; set; }
        public bool InWishlist { get; set; }
        public DateTime ActionTimestamp { get; set; } = DateTime.UtcNow;
    }
}
