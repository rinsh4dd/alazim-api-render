namespace MeatDelivery.Application.DTOs.Banner;

public class BannerDto
{
    public long BannerId { get; set; }
    public string? TitleEn { get; set; }
    public string? TitleAr { get; set; }
    public string? AltTextEn { get; set; }
    public string? AltTextAr { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public string LinkType { get; set; } = string.Empty;
    public long? ProductId { get; set; }
    public string? ProductNameEn { get; set; }
    public long? CategoryId { get; set; }
    public string? CategoryNameEn { get; set; }
    public long? OfferId { get; set; }
    public string? ExternalUrl { get; set; }
    public DateTime StartAt { get; set; }
    public DateTime EndAt { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
