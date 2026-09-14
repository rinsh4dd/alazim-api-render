using System.Collections.Generic;

namespace MeatDelivery.Application.DTOs.Invoice
{
    public class InvoiceItemDto
    {
        public long OrderItemId { get; set; }
        public long ProductId { get; set; }
        public string ProductCode { get; set; } = string.Empty;
        public string ProductNameEn { get; set; } = string.Empty;
        public string ProductNameAr { get; set; } = string.Empty;
        public string? UnitDescription { get; set; }
        public decimal RegularUnitPrice { get; set; }
        public decimal SellingUnitPrice { get; set; }
        public decimal CustomizationUnitPrice { get; set; }
        public decimal Quantity { get; set; }
        public decimal LineSubtotal { get; set; }
        public decimal ProductDiscountAmount { get; set; }
        public decimal LineTotal { get; set; }
        public string? SpecialInstructions { get; set; }
        public List<InvoiceItemCustomizationDto> Customizations { get; set; } = new();
    }

    public class InvoiceItemCustomizationDto
    {
        public long CustomizationOptionId { get; set; }
        public string GroupNameEn { get; set; } = string.Empty;
        public string GroupNameAr { get; set; } = string.Empty;
        public string OptionNameEn { get; set; } = string.Empty;
        public string OptionNameAr { get; set; } = string.Empty;
        public decimal AdditionalPrice { get; set; }
    }
}
