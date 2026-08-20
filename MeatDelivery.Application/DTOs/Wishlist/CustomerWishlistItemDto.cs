using System;

namespace MeatDelivery.Application.DTOs.Wishlist
{
    public class CustomerWishlistItemDto
    {
        public long ProductId { get; set; }
        public string ProductNameEn { get; set; } = string.Empty;
        public string ProductNameAr { get; set; } = string.Empty;
        public string? DescriptionEn { get; set; }
        public string? DescriptionAr { get; set; }
        public decimal Price { get; set; }
        public decimal SellingPrice { get; set; }
        public int DiscountPercentage { get; set; }
        public string? PrimaryUrl { get; set; }
        public string? UnitCode { get; set; }
        public DateTime AddedAt { get; set; }
    }
}
