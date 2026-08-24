namespace MeatDelivery.Application.DTOs.Customization
{
    public class GetTemplateGroupMappingsQueryDto
    {
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
        public long? CustomizationTemplateId { get; set; }
        public long? CustomizationGroupId { get; set; }
        public bool? IsActive { get; set; }
    }
}
