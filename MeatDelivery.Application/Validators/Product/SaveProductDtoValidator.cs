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
                .IsInEnum().WithMessage("Invalid product operation mode.");

            // ADD Mode Validations
            When(x => x.Mode == Mode.ADD, () =>
            {
                RuleFor(x => x.CategoryId)
                    .NotNull().WithMessage("CategoryId is required.")
                    .GreaterThan(0).WithMessage("Valid CategoryId is required.");

                When(x => !string.IsNullOrWhiteSpace(x.DocNo), () =>
                {
                    RuleFor(x => x.DocNo)
                        .MaximumLength(50).WithMessage("DocNo must not exceed 50 characters.");
                });

                RuleFor(x => x.ProductNameEn)
                    .NotEmpty().WithMessage("English product name is required.")
                    .MaximumLength(200).WithMessage("English product name must not exceed 200 characters.");

                RuleFor(x => x.ProductNameAr)
                    .NotEmpty().WithMessage("Arabic product name is required.")
                    .MaximumLength(200).WithMessage("Arabic product name must not exceed 200 characters.");
            });

            // EDIT Mode Validations
            When(x => x.Mode == Mode.EDIT, () =>
            {
                RuleFor(x => x.ProductId)
                    .NotNull().WithMessage("ProductId is required for editing.")
                    .GreaterThan(0).WithMessage("Valid ProductId is required.");

                When(x => x.CategoryId.HasValue, () =>
                {
                    RuleFor(x => x.CategoryId!.Value)
                        .GreaterThan(0).WithMessage("Valid CategoryId is required.");
                });
            });

            // DELETE Mode Validations
            When(x => x.Mode == Mode.DELETE, () =>
            {
                RuleFor(x => x.ProductId)
                    .NotNull().WithMessage("ProductId is required for deletion.")
                    .GreaterThan(0).WithMessage("Valid ProductId is required.");
            });
        }
    }
}
