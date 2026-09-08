using System;
using System.Collections.Generic;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Order
{
    public class PlaceOrderResponseDto
    {
        public long OrderId { get; set; }
        public string DocNo { get; set; } = string.Empty;
        public OrderStatus OrderStatus { get; set; } = OrderStatus.PLACED;
        public PaymentMethod PaymentMethod { get; set; } = PaymentMethod.COD;
        public PaymentStatus PaymentStatus { get; set; } = PaymentStatus.PENDING;

        public decimal Subtotal { get; set; }
        public decimal ProductDiscountTotal { get; set; }
        public long? CouponId { get; set; }
        public decimal CouponDiscount { get; set; }
        public decimal DeliveryCharge { get; set; }
        public decimal TotalAmount { get; set; }
        public string CurrencyCode { get; set; } = "AED";

        public DateTime PlacedAt { get; set; }

        public OrderDeliveryAddressPreviewDto? DeliveryAddress { get; set; }
        public OrderDeliverySchedulePreviewDto? DeliverySchedule { get; set; }
        public List<OrderItemPreviewDto> Items { get; set; } = new();
    }
}
