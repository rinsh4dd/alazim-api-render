using FluentValidation;
using MeatDelivery.Application.DTOs.Category;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.Validators.Category
{
    public class SaveCategoryDtoValidator : AbstractValidator<SaveCategoryDto>
    {
        public SaveCategoryDtoValidator()
        {
            RuleFor(x => x.Mode)
                .IsInEnum().WithMessage("Invalid category operation mode.");

            // ADD Mode validations
            When(x => x.Mode == Mode.ADD, () =>
            {
                RuleFor(x => x.CategoryNameEn)
                    .NotEmpty().WithMessage("English category name is required.")
                    .MaximumLength(150).WithMessage("Category name (EN) must not exceed 150 characters.");

                When(x => !string.IsNullOrWhiteSpace(x.CategoryCode), () =>
                {
                    RuleFor(x => x.CategoryCode)
                        .MaximumLength(50).WithMessage("Category code must not exceed 50 characters.");
                });

                When(x => !string.IsNullOrWhiteSpace(x.CategoryNameAr), () =>
                {
                    RuleFor(x => x.CategoryNameAr)
                        .MaximumLength(150).WithMessage("Category name (AR) must not exceed 150 characters.");
                });

                When(x => !string.IsNullOrWhiteSpace(x.DescriptionEn), () =>
                {
                    RuleFor(x => x.DescriptionEn)
                        .MaximumLength(500).WithMessage("English description must not exceed 500 characters.");
                });

                When(x => !string.IsNullOrWhiteSpace(x.DescriptionAr), () =>
                {
                    RuleFor(x => x.DescriptionAr)
                        .MaximumLength(500).WithMessage("Arabic description must not exceed 500 characters.");
                });

                When(x => x.ParentCategoryId.HasValue, () =>
                {
                    RuleFor(x => x.ParentCategoryId!.Value)
                        .GreaterThan(0).WithMessage("Valid ParentCategoryId is required.");
                });

                When(x => x.DisplayOrder.HasValue, () =>
                {
                    RuleFor(x => x.DisplayOrder!.Value)
                        .GreaterThanOrEqualTo(0).WithMessage("Display order must be greater than or equal to 0.");
                });
            });

            // EDIT Mode validations
            When(x => x.Mode == Mode.EDIT, () =>
            {
                RuleFor(x => x.CategoryId)
                    .NotNull().WithMessage("CategoryId is required for editing.")
                    .GreaterThan(0).WithMessage("Valid CategoryId is required.");

                When(x => !string.IsNullOrWhiteSpace(x.CategoryNameEn), () =>
                {
                    RuleFor(x => x.CategoryNameEn)
                        .MaximumLength(150).WithMessage("Category name (EN) must not exceed 150 characters.");
                });

                When(x => !string.IsNullOrWhiteSpace(x.CategoryNameAr), () =>
                {
                    RuleFor(x => x.CategoryNameAr)
                        .MaximumLength(150).WithMessage("Category name (AR) must not exceed 150 characters.");
                });

                When(x => x.ParentCategoryId.HasValue, () =>
                {
                    RuleFor(x => x.ParentCategoryId!.Value)
                        .GreaterThan(0).WithMessage("Valid ParentCategoryId is required.");
                });

                When(x => x.DisplayOrder.HasValue, () =>
                {
                    RuleFor(x => x.DisplayOrder!.Value)
                        .GreaterThanOrEqualTo(0).WithMessage("Display order must be greater than or equal to 0.");
                });
            });

            // DELETE Mode validations
            When(x => x.Mode == Mode.DELETE, () =>
            {
                RuleFor(x => x.CategoryId)
                    .NotNull().WithMessage("CategoryId is required for deletion.")
                    .GreaterThan(0).WithMessage("Valid CategoryId is required.");
            });
        }
    }
}
