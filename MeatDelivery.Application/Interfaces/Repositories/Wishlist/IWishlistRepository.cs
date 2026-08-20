using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Wishlist;

namespace MeatDelivery.Application.Interfaces.Repositories.Wishlist
{
    public interface IWishlistRepository
    {
        Task<WishlistToggleResponseDto?> ToggleWishlistAsync(long customerUserId, ToggleWishlistDto request, CancellationToken cancellationToken = default);
        Task<(List<CustomerWishlistItemDto> Items, int TotalRecords)> GetCustomerWishlistAsync(long customerUserId, GetWishlistQueryDto query, CancellationToken cancellationToken = default);
    }
}
