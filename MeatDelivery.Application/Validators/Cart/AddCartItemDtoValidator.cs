using FluentValidation;
using MeatDelivery.Application.DTOs.Cart;

namespace MeatDelivery.Application.Validators.Cart
{
    public class AddCartItemDtoValidator : AbstractValidator<AddCartItemDto>
    {
        public AddCartItemDtoValidator()
        {
            RuleFor(x => x.ProductId)
                .GreaterThan(0).WithMessage("Valid ProductId is required.");

            RuleFor(x => x.Quantity)
                .GreaterThan(0).WithMessage("Quantity must be greater than zero.");

            RuleFor(x => x.SpecialInstructions)
                .MaximumLength(500).WithMessage("Special instructions cannot exceed 500 characters.");
        }
    }
}
