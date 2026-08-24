using FluentValidation;
using MeatDelivery.Application.DTOs.Customization;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.Validators.Customization
{
    public class SaveCustomizationGroupDtoValidator : AbstractValidator<SaveCustomizationGroupDto>
    {
        public SaveCustomizationGroupDtoValidator()
        {
            RuleFor(x => x.Mode)
                .IsInEnum()
                .WithMessage("Mode must be ADD, EDIT, or DELETE.");

            // EDIT and DELETE require CustomizationGroupId
            When(x => x.Mode == Mode.EDIT || x.Mode == Mode.DELETE, () =>
            {
                RuleFor(x => x.CustomizationGroupId)
                    .NotNull()
                    .GreaterThan(0)
                    .WithMessage("Valid CustomizationGroupId is required.");
            });

            // ADD and EDIT require GroupCode, GroupNameEn, GroupNameAr
            When(x => x.Mode == Mode.ADD || x.Mode == Mode.EDIT, () =>
            {
                RuleFor(x => x.GroupCode)
                    .NotEmpty()
                    .WithMessage("Group code is required.")
                    .MaximumLength(50)
                    .WithMessage("Group code cannot exceed 50 characters.");

                RuleFor(x => x.GroupNameEn)
                    .NotEmpty()
                    .WithMessage("English group name is required.")
                    .MaximumLength(150)
                    .WithMessage("English group name cannot exceed 150 characters.");

                RuleFor(x => x.GroupNameAr)
                    .NotEmpty()
                    .WithMessage("Arabic group name is required.")
                    .MaximumLength(150)
                    .WithMessage("Arabic group name cannot exceed 150 characters.");
            });
        }
    }
}
