namespace MeatDelivery.Application.DTOs.Product
{
    public class GetProductsQueryDto
    {
        public string UserType { get; set; } = "GUEST"; // 'GUEST', 'USER', 'ADMIN'
        public long? UserId { get; set; }
        public long? ProductId { get; set; }
        public long? CategoryId { get; set; }
        public string? SearchTerm { get; set; }
        public bool? IsFeatured { get; set; }
        public bool? IsBestseller { get; set; }
        public bool? IsActive { get; set; }
        public bool? IsDeleted { get; set; }
        public bool? IsWishlistedOnly { get; set; }
        public bool? IsRecentlyOrderedOnly { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
        public string SortBy { get; set; } = "DisplayOrder";
        public string SortOrder { get; set; } = "ASC";
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }
}
