using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Wishlist;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Wishlist
{
    public interface IWishlistService
    {
        Task<ApiResponse<WishlistToggleResponseDto>> ToggleWishlistAsync(long customerUserId, ToggleWishlistDto request, CancellationToken cancellationToken = default);
        Task<PagedResponse<List<CustomerWishlistItemDto>>> GetCustomerWishlistAsync(long customerUserId, GetWishlistQueryDto query, CancellationToken cancellationToken = default);
    }
}
