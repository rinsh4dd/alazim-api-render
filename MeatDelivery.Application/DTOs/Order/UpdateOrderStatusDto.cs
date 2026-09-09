namespace MeatDelivery.Application.DTOs.Order
{
    public class UpdateOrderStatusDto
    {
        public long OrderId { get; set; }
        public string OrderStatus { get; set; } = string.Empty;
        public string? Remarks { get; set; }
    }
}
