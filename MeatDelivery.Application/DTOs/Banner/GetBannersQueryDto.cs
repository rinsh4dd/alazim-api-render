namespace MeatDelivery.Application.DTOs.Banner;

public class GetBannersQueryDto
{
    public long? BannerId { get; set; }
    public bool? IsActive { get; set; }
    public string? LinkType { get; set; }
    public string? Search { get; set; }
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 10;
}
