using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentValidation;
using Microsoft.Extensions.Caching.Memory;
using MeatDelivery.Application.DTOs.Offer;
using MeatDelivery.Application.Interfaces.Offer;
using MeatDelivery.Application.Interfaces.Repositories.Offer;
using MeatDelivery.Infrastructure.Helpers;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Infrastructure.Services.Offer
{
    public class OfferService : IOfferService
    {
        private readonly IOfferRepository _offerRepository;
        private readonly IValidator<SaveOfferDto> _validator;
        private readonly IMemoryCache _cache;
        private static CancellationTokenSource _offerCacheTokenSource = new();

        public OfferService(
            IOfferRepository offerRepository,
            IValidator<SaveOfferDto> validator,
            IMemoryCache cache)
        {
            _offerRepository = offerRepository;
            _validator = validator;
            _cache = cache;
        }

        public async Task<ApiResponse<long>> SaveOfferAsync(SaveOfferDto request, CancellationToken cancellationToken = default)
        {
            var validationResult = await _validator.ValidateAsync(request, cancellationToken);
            if (!validationResult.IsValid)
            {
                return ApiResponse<long>.FailureResponse(
                    "Validation failed.",
                    validationResult.Errors.Select(e => e.ErrorMessage).ToList()
                );
            }

            long offerId = await _offerRepository.SaveOfferAsync(request, cancellationToken);
            CacheHelper.InvalidateToken(ref _offerCacheTokenSource);

            string actionMsg = string.Equals(request.Mode, "ADD", StringComparison.OrdinalIgnoreCase)
                ? "Offer created successfully."
                : string.Equals(request.Mode, "EDIT", StringComparison.OrdinalIgnoreCase)
                    ? "Offer updated successfully."
                    : "Offer deleted successfully.";

            return ApiResponse<long>.SuccessResponse(offerId, actionMsg);
        }

        public async Task<PagedResponse<List<OfferDto>>> GetOffersAsync(GetOffersQueryDto query, CancellationToken cancellationToken = default)
        {
            var (items, totalRecords) = await _offerRepository.GetOffersAsync(query, cancellationToken);
            var itemList = items.ToList();

            return new PagedResponse<List<OfferDto>>
            {
                Success = true,
                Message = "Offers retrieved successfully.",
                Data = itemList,
                PageNumber = query.PageNumber,
                PageSize = query.PageSize,
                TotalRecords = totalRecords
            };
        }

        public async Task<ApiResponse<List<ActiveOfferDto>>> GetActiveOffersAsync(CancellationToken cancellationToken = default)
        {
            string cacheKey = "offers:active";
            if (_cache.TryGetValue(cacheKey, out ApiResponse<List<ActiveOfferDto>>? cachedResponse) && cachedResponse != null)
            {
                return cachedResponse;
            }

            var activeOffers = (await _offerRepository.GetActiveOffersAsync(cancellationToken)).ToList();
            var response = ApiResponse<List<ActiveOfferDto>>.SuccessResponse(activeOffers, "Active offers retrieved successfully.");

            _cache.Set(cacheKey, response, CacheHelper.CreateOptions(_offerCacheTokenSource, TimeSpan.FromMinutes(30)));
            return response;
        }
    }
}
