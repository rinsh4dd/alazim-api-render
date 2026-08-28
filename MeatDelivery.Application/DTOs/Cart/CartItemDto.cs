using System.Collections.Generic;

namespace MeatDelivery.Application.DTOs.Cart
{
    public class CartItemDto
    {
        public long CartItemId { get; set; }
        public long CartId { get; set; }
        public string DocNo { get; set; } = string.Empty;
        public long ProductId { get; set; }
        public string ProductNameEn { get; set; } = string.Empty;
        public string ProductNameAr { get; set; } = string.Empty;
        public string? ProductImage { get; set; }
        public string? UnitDescription { get; set; }
        public int Quantity { get; set; }
        public string? SpecialInstructions { get; set; }
        public string ItemStatus { get; set; } = "ACTIVE";
        public string ItemSignature { get; set; } = string.Empty;
        public decimal BasePrice { get; set; }
        public decimal CustomizationExtraPrice { get; set; }
        public decimal TotalUnitPrice { get; set; }
        public decimal LineTotalPrice { get; set; }

        public List<CartItemCustomizationDto> Customizations { get; set; } = new List<CartItemCustomizationDto>();
    }
}
