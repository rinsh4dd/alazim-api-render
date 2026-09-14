namespace MeatDelivery.Application.DTOs.Product
{
    public class GetCustomerProductsQueryDto
    {
        public long? ProductId { get; set; }
        public long? CategoryId { get; set; }
        public string? SearchTerm { get; set; }
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }
}

