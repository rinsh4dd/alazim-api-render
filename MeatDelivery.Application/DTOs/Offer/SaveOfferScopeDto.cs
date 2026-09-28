namespace MeatDelivery.Application.DTOs.Offer
{
    public class SaveOfferScopeDto
    {
        public string ScopeType { get; set; } = "ALL"; // ALL, CATEGORY, PRODUCT
        public long? CategoryId { get; set; }
        public long? ProductId { get; set; }
    }
}
