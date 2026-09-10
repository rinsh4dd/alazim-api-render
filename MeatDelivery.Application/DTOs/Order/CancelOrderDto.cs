using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Order
{
    public class CancelOrderDto
    {
        public long OrderId { get; set; }
        public CancelReason Reason { get; set; }
        public string? Remarks { get; set; }
    }
}
