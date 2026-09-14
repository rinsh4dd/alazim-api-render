using System;

namespace MeatDelivery.Domain.Entities.Coupon
{
    public class CouponUsage
    {
        public long CouponUsageId { get; set; }
        public long CouponId { get; set; }
        public long CustomerUserId { get; set; }
        public long OrderId { get; set; }
        public string UsageStatus { get; set; } = "USED";
        public DateTime UsedAt { get; set; } = DateTime.UtcNow;
        public DateTime? ReversedAt { get; set; }
    }
}
