using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Cart;

namespace MeatDelivery.Application.Interfaces.Cart
{
    public interface ICartRepository
    {
        Task<bool> AddToCartAsync(long customerUserId, AddCartItemDto dto);
        Task<bool> UpdateCartItemQuantityAsync(long customerUserId, UpdateCartItemQuantityDto dto);
    }
}
