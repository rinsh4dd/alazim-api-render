using FluentValidation;
using MeatDelivery.Application.DTOs.Customization;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.Validators.Customization
{
    public class SaveCustomizationOptionDtoValidator : AbstractValidator<SaveCustomizationOptionDto>
    {
        public SaveCustomizationOptionDtoValidator()
        {
            RuleFor(x => x.Mode)
                .IsInEnum().WithMessage("Invalid Mode specified. Must be ADD, EDIT, or DELETE.");

            When(x => x.Mode == Mode.ADD, () =>
            {
                RuleFor(x => x.CustomizationGroupId)
                    .GreaterThan(0).WithMessage("CustomizationGroupId is required for ADD mode.");

                RuleFor(x => x.OptionCode)
                    .NotEmpty().WithMessage("Option code is required.")
                    .MaximumLength(50).WithMessage("Option code cannot exceed 50 characters.");

                RuleFor(x => x.OptionNameEn)
                    .NotEmpty().WithMessage("English option name is required.")
                    .MaximumLength(150).WithMessage("English option name cannot exceed 150 characters.");

                RuleFor(x => x.OptionNameAr)
                    .NotEmpty().WithMessage("Arabic option name is required.")
                    .MaximumLength(150).WithMessage("Arabic option name cannot exceed 150 characters.");

                RuleFor(x => x.AdditionalPrice)
                    .GreaterThanOrEqualTo(0).WithMessage("Additional price must be greater than or equal to 0.");
            });

            When(x => x.Mode == Mode.EDIT, () =>
            {
                RuleFor(x => x.CustomizationOptionId)
                    .NotNull().WithMessage("CustomizationOptionId is required for EDIT mode.")
                    .GreaterThan(0).WithMessage("CustomizationOptionId must be greater than 0.");

                RuleFor(x => x.OptionCode)
                    .NotEmpty().WithMessage("Option code is required.")
                    .MaximumLength(50).WithMessage("Option code cannot exceed 50 characters.");

                RuleFor(x => x.OptionNameEn)
                    .NotEmpty().WithMessage("English option name is required.")
                    .MaximumLength(150).WithMessage("English option name cannot exceed 150 characters.");

                RuleFor(x => x.OptionNameAr)
                    .NotEmpty().WithMessage("Arabic option name is required.")
                    .MaximumLength(150).WithMessage("Arabic option name cannot exceed 150 characters.");

                RuleFor(x => x.AdditionalPrice)
                    .GreaterThanOrEqualTo(0).WithMessage("Additional price must be greater than or equal to 0.");
            });

            When(x => x.Mode == Mode.DELETE, () =>
            {
                RuleFor(x => x.CustomizationOptionId)
                    .NotNull().WithMessage("CustomizationOptionId is required for DELETE mode.")
                    .GreaterThan(0).WithMessage("CustomizationOptionId must be greater than 0.");
            });
        }
    }
}
