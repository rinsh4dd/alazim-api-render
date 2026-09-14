using System;

namespace MeatDelivery.Application.DTOs.Coupon
{
    public class CouponDto
    {
        public long CouponId { get; set; }
        public string CouponCode { get; set; } = string.Empty;
        public string CouponName { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string DiscountType { get; set; } = string.Empty; // 'PERCENTAGE' or 'FIXED_AMOUNT'
        public decimal DiscountValue { get; set; }
        public decimal MinimumOrderAmount { get; set; }
        public decimal? MaxDiscountAmount { get; set; }
        public int? UsageLimitGlobal { get; set; }
        public int? UsageLimitPerUser { get; set; }
        public int TimesUsed { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
