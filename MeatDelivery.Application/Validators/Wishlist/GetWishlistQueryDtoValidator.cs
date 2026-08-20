using FluentValidation;
using MeatDelivery.Application.DTOs.Wishlist;

namespace MeatDelivery.Application.Validators.Wishlist
{
    public class GetWishlistQueryDtoValidator : AbstractValidator<GetWishlistQueryDto>
    {
        public GetWishlistQueryDtoValidator()
        {
            RuleFor(x => x.PageNumber)
                .GreaterThanOrEqualTo(1).WithMessage("PageNumber must be at least 1.");

            RuleFor(x => x.PageSize)
                .InclusiveBetween(1, 100).WithMessage("PageSize must be between 1 and 100.");
        }
    }
}
