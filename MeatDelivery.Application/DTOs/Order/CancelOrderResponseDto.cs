using System;

namespace MeatDelivery.Application.DTOs.Order
{
    public class CancelOrderResponseDto
    {
        public long OrderId { get; set; }
        public string DocNo { get; set; } = string.Empty;
        public string PreviousStatus { get; set; } = string.Empty;
        public string NewStatus { get; set; } = "CANCELLED";
        public DateTime CancelledAtUae { get; set; }
    }
}
