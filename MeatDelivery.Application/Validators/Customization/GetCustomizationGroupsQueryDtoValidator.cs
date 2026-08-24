using FluentValidation;
using MeatDelivery.Application.DTOs.Customization;

namespace MeatDelivery.Application.Validators.Customization
{
    public class GetCustomizationGroupsQueryDtoValidator : AbstractValidator<GetCustomizationGroupsQueryDto>
    {
        public GetCustomizationGroupsQueryDtoValidator()
        {
            RuleFor(x => x.PageNumber)
                .GreaterThan(0)
                .WithMessage("PageNumber must be greater than 0.");

            RuleFor(x => x.PageSize)
                .GreaterThan(0)
                .WithMessage("PageSize must be greater than 0.")
                .LessThanOrEqualTo(100)
                .WithMessage("PageSize cannot exceed 100.");
        }
    }
}
