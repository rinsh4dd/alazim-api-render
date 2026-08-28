using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Cart;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Cart
{
    public interface ICartService
    {
        Task<ApiResponse<string>> AddToCartAsync(long customerUserId, AddCartItemDto dto, CancellationToken cancellationToken = default);
        Task<ApiResponse<string>> UpdateQuantityAsync(long customerUserId, UpdateCartItemQuantityDto dto, CancellationToken cancellationToken = default);
    }
}
