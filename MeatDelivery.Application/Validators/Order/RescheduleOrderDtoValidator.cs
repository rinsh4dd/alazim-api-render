using FluentValidation;
using MeatDelivery.Application.DTOs.Order;

namespace MeatDelivery.Application.Validators.Order
{
    public class RescheduleOrderDtoValidator : AbstractValidator<RescheduleOrderDto>
    {
        public RescheduleOrderDtoValidator()
        {
            RuleFor(x => x.OrderId)
                .GreaterThan(0).WithMessage("Valid OrderId is required.");

            RuleFor(x => x.NewDeliveryDate)
                .NotEmpty().WithMessage("New delivery date is required.");

            RuleFor(x => x.NewDeliverySlotEndTime)
                .GreaterThan(x => x.NewDeliverySlotStartTime)
                .WithMessage("Slot end time must be after slot start time.");
        }
    }
}
