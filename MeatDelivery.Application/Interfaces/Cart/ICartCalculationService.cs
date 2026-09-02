using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Cart;

namespace MeatDelivery.Application.Interfaces.Cart
{
    public interface ICartCalculationService
    {
        Task<CustomerCartSummaryDto> CalculateActiveCartAsync(long customerUserId, CancellationToken cancellationToken = default);
    }
}
