using FluentValidation;
using MeatDelivery.Application.DTOs.Customization;

namespace MeatDelivery.Application.Validators.Customization
{
    public class GetTemplateGroupMappingsQueryDtoValidator : AbstractValidator<GetTemplateGroupMappingsQueryDto>
    {
        public GetTemplateGroupMappingsQueryDtoValidator()
        {
            RuleFor(x => x.PageNumber)
                .GreaterThan(0).WithMessage("Page number must be greater than 0.");

            RuleFor(x => x.PageSize)
                .GreaterThan(0).WithMessage("Page size must be greater than 0.")
                .LessThanOrEqualTo(100).WithMessage("Page size cannot exceed 100.");
        }
    }
}
