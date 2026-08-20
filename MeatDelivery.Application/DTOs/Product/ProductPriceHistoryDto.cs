using System;

namespace MeatDelivery.Application.DTOs.Product
{
    public class ProductPriceHistoryDto
    {
        public long PriceId { get; set; }
        public long ProductId { get; set; }
        public string ProductNameEn { get; set; } = string.Empty;
        public string ProductNameAr { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}
