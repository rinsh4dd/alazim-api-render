namespace MeatDelivery.Application.DTOs.Banner;

public class SaveBannerDto
{
    public string Mode { get; set; } = "ADD"; // "ADD", "EDIT", "DELETE"
    public long? BannerId { get; set; }
    public string? TitleEn { get; set; }
    public string? TitleAr { get; set; }
    public string? AltTextEn { get; set; }
    public string? AltTextAr { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public string LinkType { get; set; } = "NONE";
    public long? ProductId { get; set; }
    public long? CategoryId { get; set; }
    public long? OfferId { get; set; }
    public string? ExternalUrl { get; set; }
    public DateTime StartAt { get; set; }
    public DateTime EndAt { get; set; }
    public bool IsActive { get; set; } = true;
    public long? ActionedBy { get; set; }
}
