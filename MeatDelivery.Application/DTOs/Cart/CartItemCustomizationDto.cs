namespace MeatDelivery.Application.DTOs.Cart
{
    public class CartItemCustomizationDto
    {
        public long CartItemId { get; set; }
        public long CustomizationOptionId { get; set; }
        public long GroupId { get; set; }
        public string GroupNameEn { get; set; } = string.Empty;
        public string GroupNameAr { get; set; } = string.Empty;
        public string OptionCode { get; set; } = string.Empty;
        public string OptionNameEn { get; set; } = string.Empty;
        public string OptionNameAr { get; set; } = string.Empty;
        public decimal AdditionalPrice { get; set; }
    }
}
