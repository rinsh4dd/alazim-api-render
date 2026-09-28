using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Offer;

namespace MeatDelivery.Application.Interfaces.Repositories.Offer
{
    public interface IOfferRepository
    {
        Task<long> SaveOfferAsync(SaveOfferDto request, CancellationToken cancellationToken = default);
        Task<(IEnumerable<OfferDto> Items, int TotalRecords)> GetOffersAsync(GetOffersQueryDto query, CancellationToken cancellationToken = default);
        Task<IEnumerable<ActiveOfferDto>> GetActiveOffersAsync(CancellationToken cancellationToken = default);
    }
}
