using System;
using System.Collections.Generic;

namespace MeatDelivery.Application.DTOs.Offer
{
    public class SaveOfferDto
    {
        public long? OfferId { get; set; }
        public string OfferTitleEn { get; set; } = string.Empty;
        public string OfferTitleAr { get; set; } = string.Empty;
        public string DiscountType { get; set; } = "PERCENTAGE"; // FLAT, PERCENTAGE
        public decimal DiscountValue { get; set; }
        public decimal? MinimumOrderAmount { get; set; }
        public decimal? MaxDiscountAmount { get; set; }
        public DateTime StartAt { get; set; } = DateTime.UtcNow;
        public DateTime EndAt { get; set; } = DateTime.UtcNow.AddDays(7);
        public bool IsActive { get; set; } = true;
        public string Mode { get; set; } = "ADD"; // ADD, EDIT, DELETE
        public long ActionedBy { get; set; }
        public List<SaveOfferScopeDto> Scopes { get; set; } = new();
    }
}
