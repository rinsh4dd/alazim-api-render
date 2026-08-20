using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Wishlist;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Wishlist;

namespace MeatDelivery.Infrastructure.Repositories.Wishlist
{
    public class WishlistRepository : IWishlistRepository
    {
        private readonly IDapperRepository _dapperRepository;

        public WishlistRepository(IDapperRepository dapperRepository)
        {
            _dapperRepository = dapperRepository ?? throw new ArgumentNullException(nameof(dapperRepository));
        }

        public async Task<WishlistToggleResponseDto?> ToggleWishlistAsync(long customerUserId, ToggleWishlistDto request, CancellationToken cancellationToken = default)
        {
            var items = await _dapperRepository.QueryAsync<WishlistToggleResponseDto>(
                "dbo.PR_TOGGLE_CUSTOMER_WISHLIST",
                new
                {
                    CUSTOMER_USER_ID = customerUserId,
                    PRODUCT_ID = request.ProductId,
                    IN_WISHLIST = (int?)null
                }
            );
            return items.FirstOrDefault();
        }

        public async Task<(List<CustomerWishlistItemDto> Items, int TotalRecords)> GetCustomerWishlistAsync(long customerUserId, GetWishlistQueryDto query, CancellationToken cancellationToken = default)
        {
            return await _dapperRepository.QueryMultipleAsync(
                "dbo.PR_GET_CUSTOMER_WISHLIST",
                async grid =>
                {
                    var totalRecords = (await grid.ReadAsync<int>()).FirstOrDefault();
                    var items = (await grid.ReadAsync<CustomerWishlistItemDto>()).ToList();
                    return (items, totalRecords);
                },
                new
                {
                    CUSTOMER_USER_ID = customerUserId,
                    PAGE_NUMBER = query.PageNumber,
                    PAGE_SIZE = query.PageSize
                }
            );
        }
    }
}
