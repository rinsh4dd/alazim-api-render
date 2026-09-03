using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Cart;

namespace MeatDelivery.Application.Interfaces.Cart
{
    public interface ICartRepository
    {
        Task<(dynamic? Header, List<dynamic> Items, List<dynamic> Options)> GetActiveCartRawDataAsync(long customerUserId);
        Task<bool> AddToCartAsync(long customerUserId, AddCartItemDto dto);
        Task<bool> UpdateCartItemQuantityAsync(long customerUserId, UpdateCartItemQuantityDto dto);
        Task<bool> UpdateCartItemCustomizationAsync(long customerUserId, UpdateCartItemCustomizationDto dto);
        Task<bool> RemoveCartItemAsync(long customerUserId, RemoveCartItemDto dto);
        Task<bool> ClearCartAsync(long customerUserId);
    }
}
