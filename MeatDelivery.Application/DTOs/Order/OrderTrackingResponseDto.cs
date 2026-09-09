using System;
using System.Collections.Generic;

namespace MeatDelivery.Application.DTOs.Order
{
    public class OrderTrackingResponseDto
    {
        public long OrderId { get; set; }
        public string DocNo { get; set; } = string.Empty;
        public string CurrentStatus { get; set; } = string.Empty;
        public string PaymentMethod { get; set; } = string.Empty;
        public string PaymentStatus { get; set; } = string.Empty;
        public decimal TotalAmount { get; set; }
        public DateTime PlacedAtUae { get; set; }

        public DateOnly DeliveryDate { get; set; }
        public TimeSpan DeliverySlotStartTime { get; set; }
        public TimeSpan DeliverySlotEndTime { get; set; }

        public string DeliveryContactNumber { get; set; } = string.Empty;
        public string DeliveryAddressSummary { get; set; } = string.Empty;
        public decimal? Latitude { get; set; }
        public decimal? Longitude { get; set; }

        public List<OrderTrackingStepDto> TrackingSteps { get; set; } = new();
    }
}
