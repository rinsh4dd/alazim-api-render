using FluentValidation;
using MeatDelivery.Application.DTOs.Product;

namespace MeatDelivery.Application.Validators.Product
{
    public class UpdateProductStatusDtoValidator : AbstractValidator<UpdateProductStatusDto>
    {
        public UpdateProductStatusDtoValidator()
        {
            RuleFor(x => x.ProductId)
                .GreaterThan(0).WithMessage("ProductId must be greater than 0.");
        }
    }
}
