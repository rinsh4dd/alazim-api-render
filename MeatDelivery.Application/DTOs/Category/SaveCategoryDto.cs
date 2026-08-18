using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Category
{
    public class SaveCategoryDto
    {
        public Mode Mode { get; set; }

        public long? CategoryId { get; set; }

        public string? CategoryCode { get; set; }

        public string? CategoryNameEn { get; set; }
        public string? CategoryNameAr { get; set; }

        public string? DescriptionEn { get; set; }
        public string? DescriptionAr { get; set; }

        public string? ImageUrl { get; set; }

        public int? DisplayOrder { get; set; }

        public bool? IsActive { get; set; }
        public bool? IsVisible { get; set; }
    }
}