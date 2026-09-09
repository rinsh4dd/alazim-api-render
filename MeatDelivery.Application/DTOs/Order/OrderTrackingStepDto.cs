using System;

namespace MeatDelivery.Application.DTOs.Order
{
    public class OrderTrackingStepDto
    {
        public string OrderStatus { get; set; } = string.Empty;
        public string? Remarks { get; set; }
        public DateTime CreatedAtUae { get; set; }
    }
}
