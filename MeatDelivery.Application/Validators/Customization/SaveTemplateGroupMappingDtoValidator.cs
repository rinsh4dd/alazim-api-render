using FluentValidation;
using MeatDelivery.Application.DTOs.Customization;

namespace MeatDelivery.Application.Validators.Customization
{
    public class SaveTemplateGroupMappingDtoValidator : AbstractValidator<SaveTemplateGroupMappingDto>
    {
        public SaveTemplateGroupMappingDtoValidator()
        {
            RuleFor(x => x.CustomizationTemplateId)
                .GreaterThan(0).WithMessage("CustomizationTemplateId is required.");

            RuleFor(x => x.GroupIds)
                .NotNull().WithMessage("GroupIds list cannot be null.");
        }
    }
}
