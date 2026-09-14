namespace MeatDelivery.Application.DTOs.Coupon
{
    public class GetCouponsQueryDto
    {
        public long? CouponId { get; set; }
        public string? CouponCode { get; set; }
        public string? CouponStatus { get; set; }
        public string? Search { get; set; }
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 10;
    }
}
