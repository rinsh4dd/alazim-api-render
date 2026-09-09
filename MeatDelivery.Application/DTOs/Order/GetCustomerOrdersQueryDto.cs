using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Order
{
    public class GetCustomerOrdersQueryDto
    {
        public long? OrderId { get; set; }
        public OrderStatus? OrderStatus { get; set; }
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 20;
    }
}
