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
        private readonly ICartCalculationService _cartCalculationService;
        private readonly IValidator<AddCartItemDto> _addCartItemValidator;
        private readonly IValidator<UpdateCartItemQuantityDto> _updateQuantityValidator;
        private readonly IValidator<UpdateCartItemCustomizationDto> _updateCustomizationValidator;
        private readonly IValidator<RemoveCartItemDto> _removeCartItemValidator;

        public CartService(
            ICartRepository cartRepository,
            ICartCalculationService cartCalculationService,
            IValidator<AddCartItemDto> addCartItemValidator,
            IValidator<UpdateCartItemQuantityDto> updateQuantityValidator,
            IValidator<UpdateCartItemCustomizationDto> updateCustomizationValidator,
            IValidator<RemoveCartItemDto> removeCartItemValidator)
        {
            _cartRepository = cartRepository;
            _cartCalculationService = cartCalculationService;
            _addCartItemValidator = addCartItemValidator;
            _updateQuantityValidator = updateQuantityValidator;
            _updateCustomizationValidator = updateCustomizationValidator;
            _removeCartItemValidator = removeCartItemValidator;
        }

        public async Task<ApiResponse<CustomerCartSummaryDto>> GetActiveCartAsync(long customerUserId, CancellationToken cancellationToken = default)
        {
            if (customerUserId <= 0)
            {
                return ApiResponse<CustomerCartSummaryDto>.FailureResponse("Valid CustomerUserId is required.");
            }

            var summary = await _cartCalculationService.CalculateActiveCartAsync(customerUserId, cancellationToken);
            return ApiResponse<CustomerCartSummaryDto>.SuccessResponse(summary, "Customer active cart retrieved successfully.");
        }

        public async Task<ApiResponse<CartItemActionResultDto>> AddToCartAsync(long customerUserId, AddCartItemDto dto, CancellationToken cancellationToken = default)
        {
            var validationResult = await _addCartItemValidator.ValidateAsync(dto, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<CartItemActionResultDto>.FailureResponse("Validation failed.", errors);
            }

            var result = await _cartRepository.AddToCartAsync(customerUserId, dto, cancellationToken);
            var res = result ?? new CartItemActionResultDto { ProductId = dto.ProductId };
            return ApiResponse<CartItemActionResultDto>.SuccessResponse(res, "Item added to cart successfully.");
        }

        public async Task<ApiResponse<CartItemActionResultDto>> UpdateQuantityAsync(long customerUserId, UpdateCartItemQuantityDto dto, CancellationToken cancellationToken = default)
        {
            var validationResult = await _updateQuantityValidator.ValidateAsync(dto, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<CartItemActionResultDto>.FailureResponse("Validation failed.", errors);
            }

            var result = await _cartRepository.UpdateCartItemQuantityAsync(customerUserId, dto, cancellationToken);
            var message = dto.Quantity <= 0 ? "Cart item removed successfully." : "Cart item quantity updated successfully.";
            var res = result ?? new CartItemActionResultDto { CartItemId = dto.CartItemId };
            return ApiResponse<CartItemActionResultDto>.SuccessResponse(res, message);
        }

        public async Task<ApiResponse<CartItemActionResultDto>> UpdateCustomizationAsync(long customerUserId, UpdateCartItemCustomizationDto dto, CancellationToken cancellationToken = default)
        {
            var validationResult = await _updateCustomizationValidator.ValidateAsync(dto, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<CartItemActionResultDto>.FailureResponse("Validation failed.", errors);
            }

            var result = await _cartRepository.UpdateCartItemCustomizationAsync(customerUserId, dto, cancellationToken);
            var res = result ?? new CartItemActionResultDto { CartItemId = dto.CartItemId };
            return ApiResponse<CartItemActionResultDto>.SuccessResponse(res, "Item customization updated successfully.");
        }

        public async Task<ApiResponse<CartItemActionResultDto>> RemoveCartItemAsync(long customerUserId, RemoveCartItemDto dto, CancellationToken cancellationToken = default)
        {
            var validationResult = await _removeCartItemValidator.ValidateAsync(dto, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<CartItemActionResultDto>.FailureResponse("Validation failed.", errors);
            }

            var result = await _cartRepository.RemoveCartItemAsync(customerUserId, dto, cancellationToken);
            var res = result ?? new CartItemActionResultDto { CartItemId = dto.CartItemId };
            return ApiResponse<CartItemActionResultDto>.SuccessResponse(res, "Item removed from cart successfully.");
        }

        public async Task<ApiResponse<string>> ClearCartAsync(long customerUserId, CancellationToken cancellationToken = default)
        {
            if (customerUserId <= 0)
            {
                return ApiResponse<string>.FailureResponse("Valid CustomerUserId is required.");
            }

            await _cartRepository.ClearCartAsync(customerUserId, cancellationToken);
            return ApiResponse<string>.SuccessResponse("Cart cleared successfully.", "Cart cleared successfully.");
        }
    }
}
