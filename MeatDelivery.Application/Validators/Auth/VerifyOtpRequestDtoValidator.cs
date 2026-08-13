using FluentValidation;
using MeatDelivery.Application.DTOs.Auth;

namespace MeatDelivery.Application.Validators.Auth
{
    public class VerifyOtpRequestDtoValidator : AbstractValidator<VerifyOtpRequestDto>
    {
        public VerifyOtpRequestDtoValidator()
        {
            RuleFor(x => x.CountryCode)
                .NotEmpty().WithMessage("Country code is required.")
                .Matches(@"^\+[1-9]\d{0,2}$").WithMessage("Country code must start with '+' followed by 1 to 2 digits (e.g. +91, +966, +971).");

            RuleFor(x => x.MobileNumber)
                .NotEmpty().WithMessage("Mobile number is required.")
                .Matches(@"^\d{7,15}$").WithMessage("Mobile number must contain between 7 and 15 digits.");

            RuleFor(x => x.OtpCode)
                .NotEmpty().WithMessage("OTP code is required.")
                .Length(4).WithMessage("OTP code must be 4 digits.");
        }
    }
}
