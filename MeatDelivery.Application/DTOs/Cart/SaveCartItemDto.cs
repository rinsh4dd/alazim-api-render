using System.Collections.Generic;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Cart
{
    public class SaveCartItemDto
    {
        public Mode Mode { get; set; } = Mode.ADD;
        public long CustomerUserId { get; set; }
        public long? CartItemId { get; set; }
        public long? ProductId { get; set; }
        public int Quantity { get; set; } = 1;
        public string? SpecialInstructions { get; set; }
        public List<long> CustomizationOptionIds { get; set; } = new List<long>();
    }
}
