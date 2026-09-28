using System;
using System.Collections.Generic;

namespace MeatDelivery.Application.DTOs.Offer
{
    public class OfferDto
    {
        public long OfferId { get; set; }
        public string OfferTitleEn { get; set; } = string.Empty;
        public string OfferTitleAr { get; set; } = string.Empty;
        public string DiscountType { get; set; } = string.Empty; // FLAT, PERCENTAGE
        public decimal DiscountValue { get; set; }
        public decimal? MinimumOrderAmount { get; set; }
        public decimal? MaxDiscountAmount { get; set; }
        public DateTime StartAt { get; set; }
        public DateTime EndAt { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public List<OfferScopeDto> Scopes { get; set; } = new();
    }
}
