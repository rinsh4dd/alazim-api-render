namespace MeatDelivery.Application.DTOs.Cart
{
    public class CartPricingSummaryDto
    {
        public decimal Subtotal { get; set; }
        public decimal DiscountAmount { get; set; }
        public decimal DiscountedSubtotal { get; set; }
        public decimal DeliveryCharge { get; set; }
        public decimal VatAmount { get; set; }
        public decimal GrandTotal { get; set; }
        public bool IsFreeDelivery { get; set; }
    }
}
