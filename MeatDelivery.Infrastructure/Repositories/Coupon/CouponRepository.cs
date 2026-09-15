using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Coupon;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Coupon;

namespace MeatDelivery.Infrastructure.Repositories.Coupon
{
    public class CouponRepository : ICouponRepository
    {
        private readonly IDapperRepository _dapperRepository;

        public CouponRepository(IDapperRepository dapperRepository)
        {
            _dapperRepository = dapperRepository;
        }

        public async Task<CouponDto?> SaveCouponAsync(SaveCouponDto request, CancellationToken cancellationToken = default)
        {
            return await _dapperRepository.QueryFirstOrDefaultAsync<CouponDto>(
                "dbo.PR_SAVE_COUPON",
                new
                {
                    MODE = request.Mode.ToString(),
                    COUPON_ID = request.CouponId,
                    COUPON_CODE = request.CouponCode,
                    DISCOUNT_TYPE = request.DiscountType,
                    DISCOUNT_VALUE = request.DiscountValue,
                    MAX_DISCOUNT_AMOUNT = request.MaxDiscountAmount,
                    MINIMUM_ORDER_AMOUNT = request.MinimumOrderAmount,
                    VALID_FROM = request.ValidFrom,
                    VALID_TO = request.ValidTo,
                    USAGE_LIMIT_TOTAL = request.UsageLimitTotal,
                    USAGE_LIMIT_PER_USER = request.UsageLimitPerUser,
                    COUPON_STATUS = request.CouponStatus,
                    COUPON_DESC = request.CouponDesc,
                    ACTIONED_BY = request.ActionedBy
                }
            );
        }

        public async Task<(IEnumerable<CouponDto> Items, int TotalRecords)> GetCouponsAsync(GetCouponsQueryDto query, CancellationToken cancellationToken = default)
        {
            return await _dapperRepository.QueryMultipleAsync(
                "dbo.PR_GET_COUPONS",
                async grid =>
                {
                    var totalRecords = (await grid.ReadAsync<int>()).FirstOrDefault();
                    var items = await grid.ReadAsync<CouponDto>();
                    return (items, totalRecords);
                },
                new
                {
                    COUPON_ID = query.CouponId,
                    COUPON_CODE = query.CouponCode,
                    COUPON_STATUS = query.CouponStatus,
                    SEARCH = query.Search,
                    PAGE_NUMBER = query.PageNumber,
                    PAGE_SIZE = query.PageSize
                }
            );
        }

        public async Task<AppliedCouponDto?> ApplyCouponAsync(long customerUserId, string couponCode, CancellationToken cancellationToken = default)
        {
            return await _dapperRepository.QueryFirstOrDefaultAsync<AppliedCouponDto>(
                "dbo.PR_APPLY_COUPON",
                new
                {
                    CUSTOMER_USER_ID = customerUserId,
                    COUPON_CODE = couponCode
                }
            );
        }

        public async Task<bool> RemoveCouponAsync(long customerUserId, CancellationToken cancellationToken = default)
        {
            await _dapperRepository.ExecuteAsync(
                "dbo.PR_REMOVE_COUPON",
                new { CUSTOMER_USER_ID = customerUserId }
            );
            return true;
        }
    }
}
