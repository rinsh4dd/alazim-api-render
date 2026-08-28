using System.Collections.Generic;

namespace MeatDelivery.Application.DTOs.Cart
{
    public class UpdateCartItemCustomizationDto
    {
        public long CartItemId { get; set; }
        public string? SpecialInstructions { get; set; }
        public List<long> CustomizationOptionIds { get; set; } = new List<long>();
    }
}
