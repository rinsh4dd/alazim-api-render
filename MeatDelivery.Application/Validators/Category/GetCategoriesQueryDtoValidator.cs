using FluentValidation;
using MeatDelivery.Application.DTOs.Category;

namespace MeatDelivery.Application.Validators.Category
{
    public class GetCategoriesQueryDtoValidator : AbstractValidator<GetCategoriesQueryDto>
    {
        public GetCategoriesQueryDtoValidator()
        {
            RuleFor(x => x.PageNumber)
                .GreaterThan(0).WithMessage("PageNumber must be greater than 0.");

            RuleFor(x => x.PageSize)
                .InclusiveBetween(1, 100).WithMessage("PageSize must be between 1 and 100.");
        }
    }
}
