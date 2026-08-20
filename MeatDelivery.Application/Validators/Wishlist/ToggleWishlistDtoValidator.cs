using FluentValidation;
using MeatDelivery.Application.DTOs.Wishlist;

namespace MeatDelivery.Application.Validators.Wishlist
{
    public class ToggleWishlistDtoValidator : AbstractValidator<ToggleWishlistDto>
    {
        public ToggleWishlistDtoValidator()
        {
            RuleFor(x => x.ProductId)
                .GreaterThan(0).WithMessage("Valid ProductId is required.");
        }
    }
}
