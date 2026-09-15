namespace MeatDelivery.Application.DTOs.Coupon
{
    public class ApplyCouponDto
    {
        public string CouponCode { get; set; } = string.Empty;
    }

    public class AppliedCouponDto
    {
        public long CouponId { get; set; }
        public string CouponCode { get; set; } = string.Empty;
        public string CouponName { get; set; } = string.Empty;
        public string DiscountType { get; set; } = string.Empty;
        public decimal DiscountValue { get; set; }
        public decimal? MaxDiscountAmount { get; set; }
        public decimal MinimumOrderAmount { get; set; }
    }
}
