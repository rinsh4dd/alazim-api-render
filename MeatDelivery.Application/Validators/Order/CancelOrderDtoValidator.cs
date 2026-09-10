using FluentValidation;
using MeatDelivery.Application.DTOs.Order;

namespace MeatDelivery.Application.Validators.Order
{
    public class CancelOrderDtoValidator : AbstractValidator<CancelOrderDto>
    {
        public CancelOrderDtoValidator()
        {
            RuleFor(x => x.OrderId)
                .GreaterThan(0).WithMessage("Valid OrderId is required.");

            RuleFor(x => x.Reason)
                .IsInEnum().WithMessage("A valid cancellation reason must be provided.");
        }
    }
}
