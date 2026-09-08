using System.Collections.Generic;

namespace MeatDelivery.Application.DTOs.Order
{
    public class OrderPreviewResponseDto
    {
        public long CartId { get; set; }
        public OrderDeliveryAddressPreviewDto? DeliveryAddress { get; set; }
        public OrderDeliverySchedulePreviewDto? DeliverySchedule { get; set; }
        public List<OrderItemPreviewDto> Items { get; set; } = new();

        public double DistanceKm { get; set; }
        public decimal Subtotal { get; set; }
        public decimal ProductDiscountTotal { get; set; }
        public long? CouponId { get; set; }
        public string? CouponCode { get; set; }
        public decimal CouponDiscount { get; set; }
        public decimal DeliveryCharge { get; set; }
        public decimal TotalAmount { get; set; }
        public string CurrencyCode { get; set; } = "AED";
    }
}
