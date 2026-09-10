using System;

namespace MeatDelivery.Application.DTOs.Order
{
    public class RescheduleOrderResponseDto
    {
        public long OrderId { get; set; }
        public string DocNo { get; set; } = string.Empty;
        public DateTime PreviousDeliveryDate { get; set; }
        public TimeSpan PreviousSlotStartTime { get; set; }
        public TimeSpan PreviousSlotEndTime { get; set; }
        public DateTime NewDeliveryDate { get; set; }
        public TimeSpan NewSlotStartTime { get; set; }
        public TimeSpan NewSlotEndTime { get; set; }
        public DateTime RescheduledAtUae { get; set; }
    }
}
