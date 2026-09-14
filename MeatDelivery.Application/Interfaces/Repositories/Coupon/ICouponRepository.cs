using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Coupon;

namespace MeatDelivery.Application.Interfaces.Repositories.Coupon
{
    public interface ICouponRepository
    {
        Task<CouponDto?> SaveCouponAsync(SaveCouponDto request, CancellationToken cancellationToken = default);
        Task<(IEnumerable<CouponDto> Items, int TotalRecords)> GetCouponsAsync(GetCouponsQueryDto query, CancellationToken cancellationToken = default);
    }
}
