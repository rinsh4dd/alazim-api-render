using FluentValidation;
using MeatDelivery.Application.DTOs.Product;

namespace MeatDelivery.Application.Validators.Product
{
    public class ManageAttributesDtoValidator : AbstractValidator<ManageAttributesDto>
    {
        public ManageAttributesDtoValidator()
        {
            RuleFor(x => x.Mode)
                .IsInEnum().WithMessage("Invalid Mode specified. Allowed modes: FEATURED, PREORDERABLE, NEW_ARRIVAL.");

            RuleFor(x => x.ProductIds)
                .NotEmpty().WithMessage("At least one ProductId is required.");
        }
    }
}
