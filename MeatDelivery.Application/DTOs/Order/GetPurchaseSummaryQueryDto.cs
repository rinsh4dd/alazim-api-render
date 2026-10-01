using System;

namespace MeatDelivery.Application.DTOs.Order
{
    public class GetPurchaseSummaryQueryDto
    {
        public long? ProductId { get; set; }
        public long? CustomerUserId { get; set; }
        public DateOnly? FromDate { get; set; }
        public DateOnly? ToDate { get; set; }
    }
}
