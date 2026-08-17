namespace MeatDelivery.Application.DTOs.Category
{
    public class CategoryDto
    {
        public long CategoryId { get; set; }
        public long? ParentCategoryId { get; set; }

        public string CategoryCode { get; set; } = string.Empty;

        public string CategoryNameEn { get; set; } = string.Empty;
        public string? CategoryNameAr { get; set; }

        public string? DescriptionEn { get; set; }
        public string? DescriptionAr { get; set; }

        public string? ImageUrl { get; set; }

        public int DisplayOrder { get; set; }

        public bool IsActive { get; set; }
        public bool IsVisible { get; set; }

        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}