using System;

namespace MeatDelivery.Domain.Entities.Cart
{
    public class CartItemCustomization
    {
        public long CartItemCustomizationId { get; set; }
        public long CartItemId { get; set; }
        public string DocNo { get; set; } = string.Empty;
        public long CustomizationOptionId { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
