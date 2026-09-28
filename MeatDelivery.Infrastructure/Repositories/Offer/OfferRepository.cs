using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Offer;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Offer;

namespace MeatDelivery.Infrastructure.Repositories.Offer
{
    public class OfferRepository : IOfferRepository
    {
        private readonly IDapperRepository _dapperRepository;

        public OfferRepository(IDapperRepository dapperRepository)
        {
            _dapperRepository = dapperRepository;
        }

        public async Task<long> SaveOfferAsync(SaveOfferDto request, CancellationToken cancellationToken = default)
        {
            string? scopesJson = request.Scopes != null && request.Scopes.Count > 0
                ? JsonSerializer.Serialize(request.Scopes)
                : null;

            var result = await _dapperRepository.QueryFirstOrDefaultAsync<dynamic>(
                "dbo.PR_SAVE_OFFER",
                new
                {
                    MODE = request.Mode,
                    OFFER_ID = request.OfferId,
                    OFFER_TITLE_EN = request.OfferTitleEn,
                    OFFER_TITLE_AR = request.OfferTitleAr,
                    DISCOUNT_TYPE = request.DiscountType,
                    DISCOUNT_VALUE = request.DiscountValue,
                    MINIMUM_ORDER_AMOUNT = request.MinimumOrderAmount,
                    MAX_DISCOUNT_AMOUNT = request.MaxDiscountAmount,
                    START_AT = request.StartAt,
                    END_AT = request.EndAt,
                    IS_ACTIVE = request.IsActive,
                    SCOPES_JSON = scopesJson,
                    ACTIONED_BY = request.ActionedBy
                }
            );

            if (result != null)
            {
                var dictionary = (IDictionary<string, object>)result;
                var kvp = dictionary.FirstOrDefault(k => string.Equals(k.Key, "OfferId", StringComparison.OrdinalIgnoreCase));
                if (kvp.Value != null)
                {
                    return System.Convert.ToInt64(kvp.Value);
                }
            }

            return request.OfferId ?? 0;
        }

        public async Task<(IEnumerable<OfferDto> Items, int TotalRecords)> GetOffersAsync(GetOffersQueryDto query, CancellationToken cancellationToken = default)
        {
            return await _dapperRepository.QueryMultipleAsync(
                "dbo.PR_GET_OFFERS",
                async grid =>
                {
                    var totalRecords = (await grid.ReadAsync<int>()).FirstOrDefault();
                    var headers = (await grid.ReadAsync<OfferDto>()).ToList();
                    var scopes = (await grid.ReadAsync<OfferScopeDto>()).ToList();

                    var scopesByOffer = scopes.GroupBy(s => s.OfferId)
                        .ToDictionary(g => g.Key, g => g.ToList());

                    foreach (var offer in headers)
                    {
                        if (scopesByOffer.TryGetValue(offer.OfferId, out var offerScopes))
                        {
                            offer.Scopes = offerScopes;
                        }
                    }

                    return (headers, totalRecords);
                },
                new
                {
                    OFFER_ID = query.OfferId,
                    DISCOUNT_TYPE = query.DiscountType,
                    SEARCH = query.Search,
                    IS_ACTIVE = query.IsActive,
                    PAGE_NUMBER = query.PageNumber,
                    PAGE_SIZE = query.PageSize
                }
            );
        }

        public async Task<IEnumerable<ActiveOfferDto>> GetActiveOffersAsync(CancellationToken cancellationToken = default)
        {
            return await _dapperRepository.QueryMultipleAsync(
                "dbo.PR_GET_ACTIVE_OFFERS",
                async grid =>
                {
                    var headers = (await grid.ReadAsync<ActiveOfferDto>()).ToList();
                    var scopes = (await grid.ReadAsync<OfferScopeDto>()).ToList();

                    var scopesByOffer = scopes.GroupBy(s => s.OfferId)
                        .ToDictionary(g => g.Key, g => g.ToList());

                    foreach (var offer in headers)
                    {
                        if (scopesByOffer.TryGetValue(offer.OfferId, out var offerScopes))
                        {
                            offer.Scopes = offerScopes;
                        }
                    }

                    return headers;
                },
                new { }
            );
        }
    }
}
