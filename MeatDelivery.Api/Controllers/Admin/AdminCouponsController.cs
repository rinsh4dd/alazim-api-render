using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MeatDelivery.Application.Interfaces.Coupon;

namespace MeatDelivery.Api.Controllers.Admin
{
    [ApiController]
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/admin/coupons")]
    [Authorize]
    public class AdminCouponsController : BaseApiController
    {
        private readonly ICouponService _couponService;

        public AdminCouponsController(ICouponService couponService)
        {
            _couponService = couponService;
        }
    }
}
