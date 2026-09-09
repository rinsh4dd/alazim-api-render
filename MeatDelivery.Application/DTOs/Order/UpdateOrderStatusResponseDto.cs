namespace MeatDelivery.Application.DTOs.Order
{
    public class UpdateOrderStatusResponseDto
    {
        public long OrderId { get; set; }
        public string DocNo { get; set; } = string.Empty;
        public string OrderStatus { get; set; } = string.Empty;
    }
}
