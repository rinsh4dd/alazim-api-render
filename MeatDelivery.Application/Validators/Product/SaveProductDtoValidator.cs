using FluentValidation;
using MeatDelivery.Application.DTOs.Product;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.Validators.Product
{
    public class SaveProductDtoValidator : AbstractValidator<SaveProductDto>
    {
        public SaveProductDtoValidator()
        {
            RuleFor(x => x.Mode)
                .IsInEnum().WithMessage("Invalid operation mode.");

            When(x => x.Mode == Mode.DELETE, () =>
            {
                RuleFor(x => x.ProductId)
                    .NotNull().WithMessage("ProductId is required for DELETE mode.")
                    .GreaterThan(0).WithMessage("ProductId must be greater than 0.");
            });

            When(x => x.Mode == Mode.EDIT, () =>
            {
                RuleFor(x => x.ProductId)
                    .NotNull().WithMessage("ProductId is required for EDIT mode.")
                    .GreaterThan(0).WithMessage("ProductId must be greater than 0.");
            });

            When(x => x.Mode != Mode.DELETE, () =>
            {
                RuleFor(x => x.CategoryId)
                    .GreaterThan(0).WithMessage("Valid CategoryId is required.");

                RuleFor(x => x.ProductNameEn)
                    .NotEmpty().WithMessage("English Product Name is required.")
                    .MaximumLength(200).WithMessage("English Product Name must not exceed 200 characters.");

                RuleFor(x => x.ProductNameAr)
                    .NotEmpty().WithMessage("Arabic Product Name is required.")
                    .MaximumLength(200).WithMessage("Arabic Product Name must not exceed 200 characters.");

                RuleFor(x => x.UnitId)
                    .GreaterThan(0).WithMessage("Valid UnitId is required.");

                RuleFor(x => x.Price)
                    .GreaterThan(0).WithMessage("Price must be greater than 0.");

                RuleFor(x => x.DiscountPercentage)
                    .InclusiveBetween(0, 100).WithMessage("Discount percentage must be between 0 and 100.");

                RuleFor(x => x.PrimaryUrl)
                    .NotEmpty().WithMessage("Primary image URL is required.")
                    .MaximumLength(500).WithMessage("Primary image URL must not exceed 500 characters.");
            });
        }
    }
}
