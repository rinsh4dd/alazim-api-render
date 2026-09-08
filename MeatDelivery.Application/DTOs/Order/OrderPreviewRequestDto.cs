using System;

namespace MeatDelivery.Application.DTOs.Order
{
    public class OrderPreviewRequestDto
    {
        public long? AddressId { get; set; }
        public DateOnly? DeliveryDate { get; set; }
        public TimeSpan? DeliverySlotStartTime { get; set; }
        public TimeSpan? DeliverySlotEndTime { get; set; }
    }
}
