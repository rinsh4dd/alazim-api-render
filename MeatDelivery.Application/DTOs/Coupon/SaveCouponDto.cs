using System;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Coupon
{
    public class SaveCouponDto
    {
        public Mode Mode { get; set; } = Mode.ADD;

        public long? CouponId { get; set; }

        public string? CouponCode { get; set; }

        public string? DiscountType { get; set; } // 'PERCENTAGE' or 'FLAT'

        public decimal? DiscountValue { get; set; }

        public decimal? MaxDiscountAmount { get; set; }

        public decimal? MinimumOrderAmount { get; set; } = 0.00m;

        public DateTime? ValidFrom { get; set; }

        public DateTime? ValidTo { get; set; }

        public int? UsageLimitTotal { get; set; }

        public int? UsageLimitPerUser { get; set; }

        public string? CouponStatus { get; set; } = "ACTIVE";

        public string? CouponDesc { get; set; }

        public long? ActionedBy { get; set; }
    }
}
