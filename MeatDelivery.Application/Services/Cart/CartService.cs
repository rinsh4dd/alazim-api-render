using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentValidation;
using MeatDelivery.Application.DTOs.Cart;
using MeatDelivery.Application.Interfaces.Cart;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Services.Cart
{
    public class CartService : ICartService
    {
        private readonly ICartRepository _cartRepository;
        private readonly IValidator<AddCartItemDto> _addCartItemValidator;
        private readonly IValidator<UpdateCartItemQuantityDto> _updateQuantityValidator;

        public CartService(
            ICartRepository cartRepository,
            IValidator<AddCartItemDto> addCartItemValidator,
            IValidator<UpdateCartItemQuantityDto> updateQuantityValidator)
        {
            _cartRepository = cartRepository;
            _addCartItemValidator = addCartItemValidator;
            _updateQuantityValidator = updateQuantityValidator;
        }

        public async Task<ApiResponse<string>> AddToCartAsync(long customerUserId, AddCartItemDto dto, CancellationToken cancellationToken = default)
        {
            var validationResult = await _addCartItemValidator.ValidateAsync(dto, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<string>.FailureResponse("Validation failed.", errors);
            }

            await _cartRepository.AddToCartAsync(customerUserId, dto);
            return ApiResponse<string>.SuccessResponse("Item added to cart successfully.", "Item added to cart successfully.");
        }

        public async Task<ApiResponse<string>> UpdateQuantityAsync(long customerUserId, UpdateCartItemQuantityDto dto, CancellationToken cancellationToken = default)
        {
            var validationResult = await _updateQuantityValidator.ValidateAsync(dto, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<string>.FailureResponse("Validation failed.", errors);
            }

            await _cartRepository.UpdateCartItemQuantityAsync(customerUserId, dto);
            var message = dto.Quantity <= 0 ? "Cart item removed successfully." : "Cart item quantity updated successfully.";
            return ApiResponse<string>.SuccessResponse(message, message);
        }
    }
}
