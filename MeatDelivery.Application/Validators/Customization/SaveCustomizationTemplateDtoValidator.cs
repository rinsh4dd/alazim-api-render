using FluentValidation;
using MeatDelivery.Application.DTOs.Customization;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.Validators.Customization
{
    public class SaveCustomizationTemplateDtoValidator : AbstractValidator<SaveCustomizationTemplateDto>
    {
        public SaveCustomizationTemplateDtoValidator()
        {
            RuleFor(x => x.Mode)
                .IsInEnum().WithMessage("Invalid customization template operation mode.");

            // ADD Mode validations
            When(x => x.Mode == Mode.ADD, () =>
            {
                RuleFor(x => x.TemplateNameEn)
                    .NotEmpty().WithMessage("English template name is required.")
                    .MaximumLength(150).WithMessage("Template name (EN) must not exceed 150 characters.");

                RuleFor(x => x.TemplateNameAr)
                    .NotEmpty().WithMessage("Arabic template name is required.")
                    .MaximumLength(150).WithMessage("Template name (AR) must not exceed 150 characters.");

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
            });

            // EDIT Mode validations
            When(x => x.Mode == Mode.EDIT, () =>
            {
                RuleFor(x => x.CustomizationTemplateId)
                    .NotNull().WithMessage("CustomizationTemplateId is required for editing.")
                    .GreaterThan(0).WithMessage("Valid CustomizationTemplateId is required.");

                When(x => !string.IsNullOrWhiteSpace(x.TemplateNameEn), () =>
                {
                    RuleFor(x => x.TemplateNameEn)
                        .MaximumLength(150).WithMessage("Template name (EN) must not exceed 150 characters.");
                });

                When(x => !string.IsNullOrWhiteSpace(x.TemplateNameAr), () =>
                {
                    RuleFor(x => x.TemplateNameAr)
                        .MaximumLength(150).WithMessage("Template name (AR) must not exceed 150 characters.");
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
            });

            // DELETE Mode validations
            When(x => x.Mode == Mode.DELETE, () =>
            {
                RuleFor(x => x.CustomizationTemplateId)
                    .NotNull().WithMessage("CustomizationTemplateId is required for deletion.")
                    .GreaterThan(0).WithMessage("Valid CustomizationTemplateId is required.");
            });
        }
    }
}
