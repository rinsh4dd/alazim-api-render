using System.Collections.Generic;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Cart
{
    public class CustomerCartSummaryDto
    {
        public long CartId { get; set; }
        public string CartStatus { get; set; } = "ACTIVE";
        public int TotalItemCount { get; set; }
        public CartPricingSummaryDto Summary { get; set; } = new CartPricingSummaryDto();
        public List<CartItemDetailDto> Items { get; set; } = new List<CartItemDetailDto>();
    }

    public class CartItemDetailDto
    {
        public long CartItemId { get; set; }
        public long ProductId { get; set; }
        public string ProductNameEn { get; set; } = string.Empty;
        public string ProductNameAr { get; set; } = string.Empty;
        public string? ProductImage { get; set; }
        public string? UnitDescription { get; set; }
        public int Quantity { get; set; }
        public string? SpecialInstructions { get; set; }
        public decimal UnitPrice { get; set; }
        public decimal TotalCustomizationExtraPrice { get; set; }
        public decimal LineTotalPrice { get; set; }
        public List<CartItemOptionDetailDto> CustomizationOptions { get; set; } = new List<CartItemOptionDetailDto>();
    }

    public class CartItemOptionDetailDto
    {
        public long CustomizationOptionId { get; set; }
        public long CustomizationGroupId { get; set; }
        public string GroupNameEn { get; set; } = string.Empty;
        public string GroupNameAr { get; set; } = string.Empty;
        public string OptionCode { get; set; } = string.Empty;
        public string OptionNameEn { get; set; } = string.Empty;
        public string OptionNameAr { get; set; } = string.Empty;
        public PricingType PricingType { get; set; } = PricingType.ADDITIONAL_PRICE;
        public decimal PricingValue { get; set; }
        public decimal? SelectedValue { get; set; }
        public bool IsCustomDataAllowed { get; set; }
        public decimal OptionPrice { get; set; }
    }
}
