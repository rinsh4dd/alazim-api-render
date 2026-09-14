using FluentValidation;
using MeatDelivery.Application.DTOs.Coupon;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.Validators.Coupon
{
    public class SaveCouponDtoValidator : AbstractValidator<SaveCouponDto>
    {
        public SaveCouponDtoValidator()
        {
            RuleFor(x => x.Mode)
                .IsInEnum().WithMessage("Invalid operation mode.");

            // ADD Mode
            When(x => x.Mode == Mode.ADD, () =>
            {
                RuleFor(x => x.CouponCode)
                    .NotEmpty().WithMessage("Coupon code is required.")
                    .MaximumLength(50).WithMessage("Coupon code must not exceed 50 characters.");

                RuleFor(x => x.DiscountType)
                    .NotEmpty().WithMessage("Discount type is required.")
                    .Must(t => t == "PERCENTAGE" || t == "FLAT")
                    .WithMessage("DiscountType must be 'PERCENTAGE' or 'FLAT'.");

                RuleFor(x => x.DiscountValue)
                    .NotNull().WithMessage("Discount value is required.")
                    .GreaterThan(0).WithMessage("Discount value must be greater than 0.");

                RuleFor(x => x.ValidFrom)
                    .NotNull().WithMessage("ValidFrom date is required.");

                RuleFor(x => x.ValidTo)
                    .NotNull().WithMessage("ValidTo date is required.")
                    .GreaterThan(x => x.ValidFrom).WithMessage("ValidTo must be later than ValidFrom.");
            });

            // EDIT Mode
            When(x => x.Mode == Mode.EDIT, () =>
            {
                RuleFor(x => x.CouponId)
                    .NotNull().WithMessage("CouponId is required for editing.")
                    .GreaterThan(0).WithMessage("Valid CouponId is required.");

                When(x => !string.IsNullOrWhiteSpace(x.DiscountType), () =>
                {
                    RuleFor(x => x.DiscountType)
                        .Must(t => t == "PERCENTAGE" || t == "FLAT")
                        .WithMessage("DiscountType must be 'PERCENTAGE' or 'FLAT'.");
                });
            });

            // DELETE Mode
            When(x => x.Mode == Mode.DELETE, () =>
            {
                RuleFor(x => x.CouponId)
                    .NotNull().WithMessage("CouponId is required for deletion.")
                    .GreaterThan(0).WithMessage("Valid CouponId is required.");
            });
        }
    }
}
