namespace MeatDelivery.Application.DTOs.Customization
{
    public class GetCustomizationGroupsQueryDto
    {
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
        public string? Search { get; set; }
        public long? CustomizationGroupId { get; set; }
        public bool? IsActive { get; set; }
    }
}
