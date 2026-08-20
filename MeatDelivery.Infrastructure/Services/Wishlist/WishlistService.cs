using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentValidation;
using MeatDelivery.Application.DTOs.Wishlist;
using MeatDelivery.Application.Interfaces.Repositories.Wishlist;
using MeatDelivery.Application.Interfaces.Wishlist;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Infrastructure.Services.Wishlist
{
    public class WishlistService : IWishlistService
    {
        private readonly IWishlistRepository _wishlistRepository;
        private readonly IValidator<ToggleWishlistDto> _toggleWishlistValidator;
        private readonly IValidator<GetWishlistQueryDto> _getWishlistValidator;

        public WishlistService(
            IWishlistRepository wishlistRepository,
            IValidator<ToggleWishlistDto> toggleWishlistValidator,
            IValidator<GetWishlistQueryDto> getWishlistValidator)
        {
            _wishlistRepository = wishlistRepository ?? throw new ArgumentNullException(nameof(wishlistRepository));
            _toggleWishlistValidator = toggleWishlistValidator ?? throw new ArgumentNullException(nameof(toggleWishlistValidator));
            _getWishlistValidator = getWishlistValidator ?? throw new ArgumentNullException(nameof(getWishlistValidator));
        }

        public async Task<ApiResponse<WishlistToggleResponseDto>> ToggleWishlistAsync(long customerUserId, ToggleWishlistDto request, CancellationToken cancellationToken = default)
        {
            if (customerUserId <= 0)
            {
                return ApiResponse<WishlistToggleResponseDto>.FailureResponse("Unauthorized access. Invalid or missing user token.");
            }

            ArgumentNullException.ThrowIfNull(request);

            var validationResult = await _toggleWishlistValidator.ValidateAsync(request, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<WishlistToggleResponseDto>.FailureResponse("Validation failed.", errors);
            }

            try
            {
                var result = await _wishlistRepository.ToggleWishlistAsync(customerUserId, request, cancellationToken);
                if (result == null)
                {
                    return ApiResponse<WishlistToggleResponseDto>.FailureResponse("Failed to update wishlist status.");
                }

                string actionText = result.InWishlist ? "added to" : "removed from";
                return ApiResponse<WishlistToggleResponseDto>.SuccessResponse(result, $"Product {actionText} wishlist successfully.");
            }
            catch (Exception ex)
            {
                return ApiResponse<WishlistToggleResponseDto>.FailureResponse(ex.Message);
            }
        }

        public async Task<PagedResponse<List<CustomerWishlistItemDto>>> GetCustomerWishlistAsync(long customerUserId, GetWishlistQueryDto query, CancellationToken cancellationToken = default)
        {
            if (customerUserId <= 0)
            {
                return new PagedResponse<List<CustomerWishlistItemDto>>
                {
                    Success = false,
                    Message = "Unauthorized access. Invalid or missing user token.",
                    Data = new List<CustomerWishlistItemDto>()
                };
            }

            ArgumentNullException.ThrowIfNull(query);

            var validationResult = await _getWishlistValidator.ValidateAsync(query, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return new PagedResponse<List<CustomerWishlistItemDto>>
                {
                    Success = false,
                    Message = "Validation failed.",
                    Errors = errors,
                    Data = new List<CustomerWishlistItemDto>()
                };
            }

            try
            {
                var (items, totalRecords) = await _wishlistRepository.GetCustomerWishlistAsync(customerUserId, query, cancellationToken);
                return new PagedResponse<List<CustomerWishlistItemDto>>
                {
                    Success = true,
                    Message = "Wishlist items retrieved successfully.",
                    Data = items,
                    PageNumber = query.PageNumber,
                    PageSize = query.PageSize,
                    TotalRecords = totalRecords
                };
            }
            catch (Exception ex)
            {
                return new PagedResponse<List<CustomerWishlistItemDto>>
                {
                    Success = false,
                    Message = ex.Message,
                    Data = new List<CustomerWishlistItemDto>()
                };
            }
        }
    }
}
