using System.Threading;
using System.Threading.Tasks;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MeatDelivery.Api.Extensions;
using MeatDelivery.Application.DTOs.Coupon;
using MeatDelivery.Application.Interfaces.Coupon;
using MeatDelivery.Shared.Constants;

namespace MeatDelivery.Api.Controllers
{
    [ApiController]
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/coupons")]
    [Authorize]
    public class CouponsController : BaseApiController
    {
        private readonly ICouponService _couponService;

        public CouponsController(ICouponService couponService)
        {
            _couponService = couponService;
        }

        [HttpPost("admin/save")]
        [Authorize(Roles = UserRoles.SuperAdminOrAdmin)]
        public async Task<IActionResult> SaveCoupon([FromBody] SaveCouponDto request, CancellationToken cancellationToken = default)
        {
            request.ActionedBy = HttpContext.GetUserId();

            var response = await _couponService.SaveCouponAsync(request, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpGet]
        public async Task<IActionResult> GetCoupons([FromQuery] GetCouponsQueryDto query,CancellationToken cancellationToken = default)
        {
            var response = await _couponService.GetCouponsAsync(query, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }
    }
}
