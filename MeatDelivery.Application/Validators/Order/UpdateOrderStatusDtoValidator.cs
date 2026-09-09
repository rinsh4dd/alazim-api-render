using FluentValidation;
using MeatDelivery.Application.DTOs.Order;
using MeatDelivery.Domain.Enums;
using System;

namespace MeatDelivery.Application.Validators.Order
{
    public class UpdateOrderStatusDtoValidator : AbstractValidator<UpdateOrderStatusDto>
    {
        public UpdateOrderStatusDtoValidator()
        {
            RuleFor(x => x.OrderId)
                .GreaterThan(0).WithMessage("Valid OrderId is required.");

            RuleFor(x => x.OrderStatus)
                .NotEmpty().WithMessage("OrderStatus is required.")
                .Must(BeAValidOrderStatus).WithMessage("OrderStatus must be a valid status (e.g. PLACED, CONFIRMED, PROCESSING, OUT_FOR_DELIVERY, DELIVERED, CANCELLED).");
        }

        private bool BeAValidOrderStatus(string orderStatus)
        {
            if (string.IsNullOrWhiteSpace(orderStatus)) return false;
            return Enum.TryParse<OrderStatus>(orderStatus, true, out _);
        }
    }
}
