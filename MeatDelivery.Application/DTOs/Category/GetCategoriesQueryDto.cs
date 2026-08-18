namespace MeatDelivery.Application.DTOs.Category
{
    public class GetCategoriesQueryDto
    {
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
        public string? SearchTerm { get; set; }
        public long? CategoryId { get; set; }
        public bool? IsActive { get; set; }
    }
}
