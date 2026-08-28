using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Cart;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Cart
{
    public interface ICartService
    {
        Task<ApiResponse<string>> AddToCartAsync(long customerUserId, AddCartItemDto dto);
    }
}
