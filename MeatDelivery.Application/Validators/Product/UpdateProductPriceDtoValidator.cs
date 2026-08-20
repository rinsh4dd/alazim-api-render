using FluentValidation;
using MeatDelivery.Application.DTOs.Product;

namespace MeatDelivery.Application.Validators.Product
{
    public class UpdateProductPriceDtoValidator : AbstractValidator<UpdateProductPriceDto>
    {
        public UpdateProductPriceDtoValidator()
        {
            RuleFor(x => x.ProductId)
                .GreaterThan(0).WithMessage("Valid ProductId is required.");

            RuleFor(x => x.Price)
                .GreaterThanOrEqualTo(0).WithMessage("Price must be greater than or equal to 0.");

            When(x => x.DiscountPercentage.HasValue, () =>
            {
                RuleFor(x => x.DiscountPercentage!.Value)
                    .InclusiveBetween(0, 100).WithMessage("Discount percentage must be between 0 and 100.");
            });
        }
    }
}
