namespace MeatDelivery.Application.DTOs.Product
{
    public class GetPriceHistoryQueryDto
    {
        public long ProductId { get; set; }
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }
}
