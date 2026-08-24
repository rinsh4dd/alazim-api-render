using FluentValidation;
using MeatDelivery.Application.DTOs.Customization;

namespace MeatDelivery.Application.Validators.Customization
{
    public class GetCustomizationTemplatesQueryDtoValidator : AbstractValidator<GetCustomizationTemplatesQueryDto>
    {
        public GetCustomizationTemplatesQueryDtoValidator()
        {
            RuleFor(x => x.PageNumber)
                .GreaterThanOrEqualTo(1).WithMessage("Page number must be greater than or equal to 1.");

            RuleFor(x => x.PageSize)
                .GreaterThanOrEqualTo(1).WithMessage("Page size must be greater than or equal to 1.")
                .LessThanOrEqualTo(100).WithMessage("Page size must not exceed 100.");

            When(x => x.CustomizationTemplateId.HasValue, () =>
            {
                RuleFor(x => x.CustomizationTemplateId!.Value)
                    .GreaterThan(0).WithMessage("CustomizationTemplateId must be greater than 0.");
            });
        }
    }
}
