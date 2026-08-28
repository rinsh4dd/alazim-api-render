using System;
using System.Collections.Generic;

namespace MeatDelivery.Domain.Entities.Cart
{
    public class Cart
    {
        public long CartId { get; set; }
        public string DocType { get; set; } = "CRT1";
        public string DocNo { get; set; } = string.Empty;
        public long CustomerUserId { get; set; }
        public string CartStatus { get; set; } = "ACTIVE";
        public long? CouponId { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }

        public List<CartItem> Items { get; set; } = new List<CartItem>();
    }
}
