using System;

namespace MeatDelivery.Domain.Entities.Coupon
{
    public class Coupon
    {
        public long CouponId { get; set; }
        public string CouponCode { get; set; } = string.Empty;
        public string DiscountType { get; set; } = string.Empty;
        public decimal DiscountValue { get; set; }
        public decimal? MaxDiscountAmount { get; set; }
        public decimal MinimumOrderAmount { get; set; }
        public DateTime ValidFrom { get; set; }
        public DateTime ValidTo { get; set; }
        public int? UsageLimitTotal { get; set; }
        public int? UsageLimitPerUser { get; set; }
        public string CouponStatus { get; set; } = "ACTIVE";
        public string? CouponDesc { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}
