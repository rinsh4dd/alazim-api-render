namespace MeatDelivery.Application.DTOs.Product
{
    public class SaveProductImageDto
    {
        public long? ProductImageId { get; set; }
        public string ImageUrl { get; set; } = string.Empty;
        public bool IsPrimary { get; set; }
        public int DisplayOrder { get; set; }
        public bool IsActive { get; set; } = true;
    }
}
