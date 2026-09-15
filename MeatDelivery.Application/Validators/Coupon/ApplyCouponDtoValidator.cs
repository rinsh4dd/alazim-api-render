using FluentValidation;
using MeatDelivery.Application.DTOs.Coupon;

namespace MeatDelivery.Application.Validators.Coupon
{
    public class ApplyCouponDtoValidator : AbstractValidator<ApplyCouponDto>
    {
        public ApplyCouponDtoValidator()
        {
            RuleFor(x => x.CouponCode)
                .NotEmpty().WithMessage("Coupon code is required.")
                .MaximumLength(50).WithMessage("Coupon code cannot exceed 50 characters.");
        }
    }
}
