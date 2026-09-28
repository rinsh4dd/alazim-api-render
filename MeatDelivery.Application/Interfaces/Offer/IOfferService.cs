using MeatDelivery.Application.DTOs.Offer;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Offer
{
    public interface IOfferService
    {
        Task<ApiResponse<long>> SaveOfferAsync(SaveOfferDto request, CancellationToken cancellationToken = default);
        Task<PagedResponse<List<OfferDto>>> GetOffersAsync(GetOffersQueryDto query, CancellationToken cancellationToken = default);
        Task<ApiResponse<List<ActiveOfferDto>>> GetActiveOffersAsync(CancellationToken cancellationToken = default);
    }
}
