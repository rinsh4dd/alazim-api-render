namespace MeatDelivery.Application.DTOs.Cart
{
    public class CartItemActionResultDto
    {
        public long CartItemId { get; set; }
        public long ProductId { get; set; }
        public string ProductNameEn { get; set; } = string.Empty;
        public string ProductNameAr { get; set; } = string.Empty;
    }
}
