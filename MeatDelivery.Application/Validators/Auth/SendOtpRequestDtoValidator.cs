using FluentValidation;
using MeatDelivery.Application.DTOs.Auth;

namespace MeatDelivery.Application.Validators.Auth
{
    public class SendOtpRequestDtoValidator : AbstractValidator<SendOtpRequestDto>
    {
        public SendOtpRequestDtoValidator()
        //update digits


        {
            RuleFor(x => x.CountryCode)
                .NotEmpty().WithMessage("Country code is required.")
                .Matches(@"^\+971$").WithMessage("Country code must be '+971'.");

            RuleFor(x => x.MobileNumber)
                .NotEmpty().WithMessage("Mobile number is required.")
                .Length(9).WithMessage("Invalid mobile number.");
        }
    }   
}
