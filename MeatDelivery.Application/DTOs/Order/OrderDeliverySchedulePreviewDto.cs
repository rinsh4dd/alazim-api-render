using System;

namespace MeatDelivery.Application.DTOs.Order
{
    public class OrderDeliverySchedulePreviewDto
    {
        public DateOnly DeliveryDate { get; set; }
        public TimeSpan StartTime { get; set; }
        public TimeSpan EndTime { get; set; }
    }
}
