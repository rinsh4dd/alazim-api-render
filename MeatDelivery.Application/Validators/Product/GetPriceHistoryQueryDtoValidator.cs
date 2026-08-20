using FluentValidation;
using MeatDelivery.Application.DTOs.Product;

namespace MeatDelivery.Application.Validators.Product
{
    public class GetPriceHistoryQueryDtoValidator : AbstractValidator<GetPriceHistoryQueryDto>
    {
        public GetPriceHistoryQueryDtoValidator()
        {
            RuleFor(x => x.ProductId)
                .GreaterThan(0).WithMessage("Valid ProductId is required.");

            RuleFor(x => x.PageNumber)
                .GreaterThanOrEqualTo(1).WithMessage("PageNumber must be at least 1.");

            RuleFor(x => x.PageSize)
                .InclusiveBetween(1, 100).WithMessage("PageSize must be between 1 and 100.");
        }
    }
}
