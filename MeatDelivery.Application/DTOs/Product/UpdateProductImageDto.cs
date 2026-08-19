namespace MeatDelivery.Application.DTOs.Product
{
    public class UpdateProductImageDto
    {
        public long ProductId { get; set; }
        public string PrimaryUrl { get; set; } = string.Empty;
        public string? SecondaryUrl { get; set; }
        public string? TertiaryUrl { get; set; }
    }
}
