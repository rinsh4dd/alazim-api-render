namespace MeatDelivery.Application.DTOs.Offer
{
    public class GetOffersQueryDto
    {
        public long? OfferId { get; set; }
        public string? DiscountType { get; set; }
        public string? Search { get; set; }
        public bool? IsActive { get; set; }
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }
}
