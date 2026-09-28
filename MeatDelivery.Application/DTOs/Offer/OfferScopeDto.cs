namespace MeatDelivery.Application.DTOs.Offer
{
    public class OfferScopeDto
    {
        public long ScopeId { get; set; }
        public long OfferId { get; set; }
        public string ScopeType { get; set; } = string.Empty; // ALL, CATEGORY, PRODUCT
        public long? CategoryId { get; set; }
        public string? CategoryNameEn { get; set; }
        public long? ProductId { get; set; }
        public string? ProductNameEn { get; set; }
    }
}
