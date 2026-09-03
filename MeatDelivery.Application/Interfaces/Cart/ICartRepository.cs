using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Cart;

namespace MeatDelivery.Application.Interfaces.Cart
{
    public interface ICartRepository
    {
        Task<(dynamic? Header, List<dynamic> Items, List<dynamic> Options)> GetActiveCartRawDataAsync(long customerUserId, CancellationToken cancellationToken = default);
        Task<CartItemActionResultDto?> AddToCartAsync(long customerUserId, AddCartItemDto dto, CancellationToken cancellationToken = default);
        Task<CartItemActionResultDto?> UpdateCartItemQuantityAsync(long customerUserId, UpdateCartItemQuantityDto dto, CancellationToken cancellationToken = default);
        Task<CartItemActionResultDto?> UpdateCartItemCustomizationAsync(long customerUserId, UpdateCartItemCustomizationDto dto, CancellationToken cancellationToken = default);
        Task<CartItemActionResultDto?> RemoveCartItemAsync(long customerUserId, RemoveCartItemDto dto, CancellationToken cancellationToken = default);
        Task<bool> ClearCartAsync(long customerUserId, CancellationToken cancellationToken = default);
    }
}
