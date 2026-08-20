namespace MeatDelivery.Application.DTOs.Product
{
    public class UpdateProductPriceDto
    {
        public long ProductId { get; set; }
        public decimal Price { get; set; }
        public decimal? DiscountPercentage { get; set; }
    }
}
