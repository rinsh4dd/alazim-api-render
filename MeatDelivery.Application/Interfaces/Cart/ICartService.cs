using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Cart;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Cart
{
    public interface ICartService
    {
        Task<ApiResponse<CustomerCartSummaryDto>> GetActiveCartAsync(long customerUserId, CancellationToken cancellationToken = default);
        Task<ApiResponse<string>> AddToCartAsync(long customerUserId, AddCartItemDto dto, CancellationToken cancellationToken = default);
        Task<ApiResponse<string>> UpdateQuantityAsync(long customerUserId, UpdateCartItemQuantityDto dto, CancellationToken cancellationToken = default);
        Task<ApiResponse<string>> UpdateCustomizationAsync(long customerUserId, UpdateCartItemCustomizationDto dto, CancellationToken cancellationToken = default);
        Task<ApiResponse<string>> RemoveCartItemAsync(long customerUserId, RemoveCartItemDto dto, CancellationToken cancellationToken = default);
        Task<ApiResponse<string>> ClearCartAsync(long customerUserId, CancellationToken cancellationToken = default);
    }
}
