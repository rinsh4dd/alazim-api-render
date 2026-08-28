using FluentValidation;
using MeatDelivery.Application.DTOs.Cart;

namespace MeatDelivery.Application.Validators.Cart
{
    public class UpdateCartItemQuantityDtoValidator : AbstractValidator<UpdateCartItemQuantityDto>
    {
        public UpdateCartItemQuantityDtoValidator()
        {
            RuleFor(x => x.CartItemId)
                .GreaterThan(0).WithMessage("Valid CartItemId is required.");

            RuleFor(x => x.Quantity)
                .GreaterThanOrEqualTo(0).WithMessage("Quantity cannot be negative.");
        }
    }
}
