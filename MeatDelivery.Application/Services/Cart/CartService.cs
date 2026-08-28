using System;
using System.Linq;
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

        public CartService(ICartRepository cartRepository,IValidator<AddCartItemDto> addCartItemValidator)
        {
            _cartRepository = cartRepository;
            _addCartItemValidator = addCartItemValidator;
        }

        public async Task<ApiResponse<string>> AddToCartAsync(long customerUserId, AddCartItemDto dto)
        {
            var validationResult = await _addCartItemValidator.ValidateAsync(dto);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<string>.FailureResponse("Validation failed.", errors);
            }

            await _cartRepository.AddToCartAsync(customerUserId, dto);
            return ApiResponse<string>.SuccessResponse("Item added to cart successfully.", "Item added to cart successfully.");
        }
    }
}
