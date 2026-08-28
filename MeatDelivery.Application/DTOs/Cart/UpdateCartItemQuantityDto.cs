namespace MeatDelivery.Application.DTOs.Cart
{
    public class UpdateCartItemQuantityDto
    {
        public long CartItemId { get; set; }
        public int Quantity { get; set; }
    }
}
