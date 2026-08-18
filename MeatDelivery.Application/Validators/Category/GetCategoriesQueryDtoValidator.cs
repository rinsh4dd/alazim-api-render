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

            When(x => !string.IsNullOrWhiteSpace(x.SortBy), () =>
            {
                RuleFor(x => x.SortBy)
                    .Must(sortBy => sortBy == "DisplayOrder" || sortBy == "CategoryNameEn" || sortBy == "CategoryNameAr" || sortBy == "CreatedAt")
                    .WithMessage("Invalid SortBy value. Allowed: DisplayOrder, CategoryNameEn, CategoryNameAr, CreatedAt.");
            });

            When(x => !string.IsNullOrWhiteSpace(x.SortOrder), () =>
            {
                RuleFor(x => x.SortOrder)
                    .Must(order => order != null && (order.Equals("ASC", System.StringComparison.OrdinalIgnoreCase) || order.Equals("DESC", System.StringComparison.OrdinalIgnoreCase)))
                    .WithMessage("Invalid SortOrder value. Allowed: ASC, DESC.");
            });
        }
    }
}
