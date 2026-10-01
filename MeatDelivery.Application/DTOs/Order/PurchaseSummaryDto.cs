namespace MeatDelivery.Application.DTOs.Order
{
    public class PurchaseSummaryDto
    {
        public long ProductId { get; set; }
        public string ProductNameEn { get; set; } = string.Empty;
        public string ProductNameAr { get; set; } = string.Empty;
        public decimal TotalQuantityPurchased { get; set; }
        public int OrderCount { get; set; }
        public int CustomerCount { get; set; }
    }
}
