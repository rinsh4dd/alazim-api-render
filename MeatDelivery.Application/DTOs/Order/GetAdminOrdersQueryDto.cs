using System;

namespace MeatDelivery.Application.DTOs.Order
{
    public class GetAdminOrdersQueryDto
    {
        public long? OrderId { get; set; }
        public string? SearchTerm { get; set; }
        public long? CustomerUserId { get; set; }
        public string? OrderStatus { get; set; }
        public DateOnly? FromDate { get; set; }
        public DateOnly? ToDate { get; set; }
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 20;
    }
}
