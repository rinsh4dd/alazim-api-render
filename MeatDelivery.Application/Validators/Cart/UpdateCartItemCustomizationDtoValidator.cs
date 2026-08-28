using FluentValidation;
using MeatDelivery.Application.DTOs.Cart;

namespace MeatDelivery.Application.Validators.Cart
{
    public class UpdateCartItemCustomizationDtoValidator : AbstractValidator<UpdateCartItemCustomizationDto>
    {
        public UpdateCartItemCustomizationDtoValidator()
        {
            RuleFor(x => x.CartItemId)
                .GreaterThan(0).WithMessage("Valid CartItemId is required.");

            RuleFor(x => x.SpecialInstructions)
                .MaximumLength(500).WithMessage("Special instructions cannot exceed 500 characters.");
        }
    }
}
