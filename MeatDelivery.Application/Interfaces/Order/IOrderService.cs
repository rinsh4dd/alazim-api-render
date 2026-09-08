using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Order;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Order
{
    public interface IOrderService
    {

        Task<ApiResponse<PlaceOrderResponseDto>> PlaceOrderAsync(
            long customerUserId,
            PlaceOrderRequestDto request,
            CancellationToken cancellationToken = default);
    }
}
