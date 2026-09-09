using System;
using System.Collections.Generic;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Order
{
    public class CustomerOrderDetailDto
    {
        public long OrderId { get; set; }
        public string DocNo { get; set; } = string.Empty;
        public long CustomerUserId { get; set; }
        public OrderStatus OrderStatus { get; set; }
        public PaymentMethod PaymentMethod { get; set; }
        public PaymentStatus PaymentStatus { get; set; }
        public string CurrencyCode { get; set; } = "AED";

        public decimal Subtotal { get; set; }
        public decimal ProductDiscountTotal { get; set; }
        public long? CouponId { get; set; }
        public decimal CouponDiscount { get; set; }
        public decimal DeliveryCharge { get; set; }
        public decimal VatAmount { get; set; }
        public decimal TotalAmount { get; set; }

        public DateTime PlacedAt { get; set; }

        public OrderDeliveryAddressPreviewDto? DeliveryAddress { get; set; }
        public OrderDeliverySchedulePreviewDto? DeliverySchedule { get; set; }
        public List<OrderItemDetailDto> Items { get; set; } = new();
        public List<OrderStatusHistoryDto> StatusHistory { get; set; } = new();
    }

    public class OrderItemDetailDto
    {
        public long OrderItemId { get; set; }
        public long ProductId { get; set; }
        public string ProductCode { get; set; } = string.Empty;
        public string ProductNameEn { get; set; } = string.Empty;
        public string ProductNameAr { get; set; } = string.Empty;
        public string ProductImage { get; set; } = string.Empty;
        public string UnitDescription { get; set; } = string.Empty;

        public decimal RegularUnitPrice { get; set; }
        public decimal SellingUnitPrice { get; set; }
        public decimal CustomizationUnitPrice { get; set; }
        public int Quantity { get; set; }
        public decimal LineSubtotal { get; set; }
        public decimal ProductDiscountAmount { get; set; }
        public decimal LineTotal { get; set; }

        public string? SpecialInstructions { get; set; }
        public List<OrderItemCustomizationDetailDto> Customizations { get; set; } = new();
    }

    public class OrderItemCustomizationDetailDto
    {
        public long CustomizationOptionId { get; set; }
        public string GroupNameEn { get; set; } = string.Empty;
        public string GroupNameAr { get; set; } = string.Empty;
        public string OptionNameEn { get; set; } = string.Empty;
        public string OptionNameAr { get; set; } = string.Empty;
        public decimal AdditionalPrice { get; set; }
    }

    public class OrderStatusHistoryDto
    {
        public OrderStatus OrderStatus { get; set; }
        public string? Remarks { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
