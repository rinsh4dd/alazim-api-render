using FluentValidation;
using MeatDelivery.Application.DTOs.Product;

namespace MeatDelivery.Application.Validators.Product
{
    public class UpdateProductImageDtoValidator : AbstractValidator<UpdateProductImageDto>
    {
        public UpdateProductImageDtoValidator()
        {
            RuleFor(x => x.ProductId)
                .GreaterThan(0).WithMessage("ProductId must be greater than 0.");

            RuleFor(x => x.PrimaryUrl)
                .NotEmpty().WithMessage("PrimaryUrl is required.")
                .MaximumLength(500).WithMessage("PrimaryUrl must not exceed 500 characters.");

            RuleFor(x => x.SecondaryUrl)
                .MaximumLength(500).WithMessage("SecondaryUrl must not exceed 500 characters.")
                .When(x => !string.IsNullOrEmpty(x.SecondaryUrl));

            RuleFor(x => x.TertiaryUrl)
                .MaximumLength(500).WithMessage("TertiaryUrl must not exceed 500 characters.")
                .When(x => !string.IsNullOrEmpty(x.TertiaryUrl));
        }
    }
}
