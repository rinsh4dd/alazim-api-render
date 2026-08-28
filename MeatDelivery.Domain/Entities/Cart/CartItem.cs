using System;
using System.Collections.Generic;

namespace MeatDelivery.Domain.Entities.Cart
{
    public class CartItem
    {
        public long CartItemId { get; set; }
        public long CartId { get; set; }
        public string DocNo { get; set; } = string.Empty;
        public long ProductId { get; set; }
        public int Quantity { get; set; } = 1;
        public string? SpecialInstructions { get; set; }
        public string ItemStatus { get; set; } = "ACTIVE";
        public string ItemSignature { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }

        public List<CartItemCustomization> Customizations { get; set; } = new List<CartItemCustomization>();
    }
}
