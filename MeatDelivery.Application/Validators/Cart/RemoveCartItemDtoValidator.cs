using FluentValidation;
using MeatDelivery.Application.DTOs.Cart;

namespace MeatDelivery.Application.Validators.Cart
{
    public class RemoveCartItemDtoValidator : AbstractValidator<RemoveCartItemDto>
    {
        public RemoveCartItemDtoValidator()
        {
            RuleFor(x => x.CartItemId)
                .GreaterThan(0).WithMessage("Valid CartItemId is required.");
        }
    }
}
