using System.Collections.Generic;

namespace MeatDelivery.Application.DTOs.Order
{
    public class OrderItemPreviewDto
    {
        public long ProductId { get; set; }
        public string ProductNameEn { get; set; } = string.Empty;
        public string ProductNameAr { get; set; } = string.Empty;
        public string? ProductImage { get; set; }
        public string UnitDescription { get; set; } = string.Empty;

        public decimal RegularUnitPrice { get; set; }
        public decimal SellingUnitPrice { get; set; }
        public decimal CustomizationUnitPrice { get; set; }
        public int Quantity { get; set; }

        public decimal LineSubtotal { get; set; }
        public decimal ProductDiscountAmount { get; set; }
        public decimal LineTotal { get; set; }

        public string? SpecialInstructions { get; set; }
        public List<OrderItemCustomizationPreviewDto> Customizations { get; set; } = new();
    }
}
