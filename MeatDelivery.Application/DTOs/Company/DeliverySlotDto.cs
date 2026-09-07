using System;

namespace MeatDelivery.Application.DTOs.Company
{
    public class DeliverySlotDto
    {
        public TimeSpan StartTime { get; set; }
        public TimeSpan EndTime { get; set; }
    }
}
