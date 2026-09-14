using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Coupon;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Coupon
{
    public interface ICouponService
    {
        Task<ApiResponse<CouponDto>> SaveCouponAsync(SaveCouponDto request, CancellationToken cancellationToken = default);
        Task<PagedResponse<List<CouponDto>>> GetCouponsAsync(GetCouponsQueryDto query, CancellationToken cancellationToken = default);
    }
}
