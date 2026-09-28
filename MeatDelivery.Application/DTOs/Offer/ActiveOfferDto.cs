using System;
using System.Collections.Generic;

namespace MeatDelivery.Application.DTOs.Offer
{
    public class ActiveOfferDto
    {
        public long OfferId { get; set; }
        public string OfferTitleEn { get; set; } = string.Empty;
        public string OfferTitleAr { get; set; } = string.Empty;
        public string DiscountType { get; set; } = string.Empty;
        public decimal DiscountValue { get; set; }
        public decimal? MinimumOrderAmount { get; set; }
        public decimal? MaxDiscountAmount { get; set; }
        public DateTime StartAt { get; set; }
        public DateTime EndAt { get; set; }
        public List<OfferScopeDto> Scopes { get; set; } = new();
    }
}
