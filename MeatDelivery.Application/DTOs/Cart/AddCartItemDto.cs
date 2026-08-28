using System.Collections.Generic;

namespace MeatDelivery.Application.DTOs.Cart
{
    public class AddCartItemDto
    {
        public long ProductId { get; set; }
        public int Quantity { get; set; } = 1;
        public string? SpecialInstructions { get; set; }
        public List<long> CustomizationOptionIds { get; set; } = new List<long>();
    }
}
