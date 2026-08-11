using FluentValidation;
using MeatDelivery.Application.DTOs.Auth;

namespace MeatDelivery.Application.Validators.Auth
{
    public class SendOtpRequestDtoValidator : AbstractValidator<SendOtpRequestDto>
    {
        public SendOtpRequestDtoValidator()
        {
            RuleFor(x => x.CountryCode)
                .NotEmpty().WithMessage("Country code is required.")
                .Matches(@"^\+[1-9]\d{0,2}$").WithMessage("Country code must start with '+' followed by 1 to 3 digits (e.g. +966, +971).");

            RuleFor(x => x.MobileNumber)
                .NotEmpty().WithMessage("Mobile number is required.")
                .Matches(@"^\d{7,15}$").WithMessage("Mobile number must contain between 7 and 15 digits.");
        }
    }
}
