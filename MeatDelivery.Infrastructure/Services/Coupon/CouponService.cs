using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentValidation;
using Microsoft.Extensions.Caching.Memory;
using MeatDelivery.Application.DTOs.Cart;
using MeatDelivery.Application.DTOs.Coupon;
using MeatDelivery.Application.Interfaces.Cart;
using MeatDelivery.Application.Interfaces.Coupon;
using MeatDelivery.Application.Interfaces.Repositories.Coupon;
using MeatDelivery.Domain.Enums;
using MeatDelivery.Infrastructure.Helpers;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Infrastructure.Services.Coupon
{
    public class CouponService : ICouponService
    {
        private readonly ICouponRepository _couponRepository;
        private readonly ICartCalculationService _cartCalculationService;
        private readonly IValidator<SaveCouponDto> _saveCouponValidator;
        private readonly IValidator<ApplyCouponDto> _applyCouponValidator;
        private readonly IMemoryCache _cache;

        private static CancellationTokenSource _couponCacheTokenSource = new();

        public CouponService(
            ICouponRepository couponRepository,
            ICartCalculationService cartCalculationService,
            IValidator<SaveCouponDto> saveCouponValidator,
            IValidator<ApplyCouponDto> applyCouponValidator,
            IMemoryCache cache)
        {
            _couponRepository = couponRepository;
            _cartCalculationService = cartCalculationService;
            _saveCouponValidator = saveCouponValidator;
            _applyCouponValidator = applyCouponValidator;
            _cache = cache;
        }

        public async Task<ApiResponse<CouponDto>> SaveCouponAsync(SaveCouponDto request, CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(request);

            var validationResult = await _saveCouponValidator.ValidateAsync(request, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<CouponDto>.FailureResponse("Validation failed.", errors);
            }

            var result = await _couponRepository.SaveCouponAsync(request, cancellationToken);

            if (result == null && request.Mode != Mode.DELETE)
            {
                return ApiResponse<CouponDto>.FailureResponse("Failed to process coupon request.");
            }

            // Invalidate cached coupons on successful Add, Edit, or Delete
            CacheHelper.InvalidateToken(ref _couponCacheTokenSource);

            string message = request.Mode switch
            {
                Mode.ADD => "Coupon created successfully.",
                Mode.EDIT => "Coupon updated successfully.",
                Mode.DELETE => "Coupon deleted successfully.",
                _ => "Operation completed successfully."
            };

            return ApiResponse<CouponDto>.SuccessResponse(result!, message);
        }

        public async Task<PagedResponse<List<CouponDto>>> GetCouponsAsync(GetCouponsQueryDto query, CancellationToken cancellationToken = default)
        {
            query ??= new GetCouponsQueryDto();

            string cacheKey = $"coupons:id_{query.CouponId}_code_{query.CouponCode}_status_{query.CouponStatus}_search_{query.Search}_p_{query.PageNumber}_s_{query.PageSize}";

            if (_cache.TryGetValue(cacheKey, out PagedResponse<List<CouponDto>>? cachedResponse) && cachedResponse != null)
            {
                return cachedResponse;
            }

            var (items, totalRecords) = await _couponRepository.GetCouponsAsync(query, cancellationToken);

            var response = new PagedResponse<List<CouponDto>>
            {
                Success = true,
                Message = "Coupons retrieved successfully.",
                Data = items.ToList(),
                PageNumber = query.PageNumber,
                PageSize = query.PageSize,
                TotalRecords = totalRecords
            };

            var cacheOptions = CacheHelper.CreateOptions(_couponCacheTokenSource, TimeSpan.FromMinutes(30));
            _cache.Set(cacheKey, response, cacheOptions);

            return response;
        }

        public async Task<ApiResponse<CustomerCartSummaryDto>> ApplyCouponAsync(long customerUserId, ApplyCouponDto dto, CancellationToken cancellationToken = default)
        {
            if (customerUserId <= 0)
            {
                return ApiResponse<CustomerCartSummaryDto>.FailureResponse("Valid CustomerUserId is required.");
            }

            var validationResult = await _applyCouponValidator.ValidateAsync(dto, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<CustomerCartSummaryDto>.FailureResponse("Validation failed.", errors);
            }

            await _couponRepository.ApplyCouponAsync(customerUserId, dto.CouponCode, cancellationToken);
            var updatedCart = await _cartCalculationService.CalculateActiveCartAsync(customerUserId, cancellationToken);

            return ApiResponse<CustomerCartSummaryDto>.SuccessResponse(updatedCart, "Coupon code applied successfully.");
        }

        public async Task<ApiResponse<CustomerCartSummaryDto>> RemoveCouponAsync(long customerUserId, CancellationToken cancellationToken = default)
        {
            if (customerUserId <= 0)
            {
                return ApiResponse<CustomerCartSummaryDto>.FailureResponse("Valid CustomerUserId is required.");
            }

            await _couponRepository.RemoveCouponAsync(customerUserId, cancellationToken);
            var updatedCart = await _cartCalculationService.CalculateActiveCartAsync(customerUserId, cancellationToken);

            return ApiResponse<CustomerCartSummaryDto>.SuccessResponse(updatedCart, "Coupon code removed successfully.");
        }
    }
}
