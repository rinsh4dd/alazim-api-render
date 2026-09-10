using System;

namespace MeatDelivery.Application.DTOs.Order
{
    public class RescheduleOrderDto
    {
        public long OrderId { get; set; }
        public DateTime NewDeliveryDate { get; set; }
        public TimeSpan NewDeliverySlotStartTime { get; set; }
        public TimeSpan NewDeliverySlotEndTime { get; set; }
        public string? Remarks { get; set; }
    }
}
