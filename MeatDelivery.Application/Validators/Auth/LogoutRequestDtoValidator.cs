using FluentValidation;
using MeatDelivery.Application.DTOs.Auth;

namespace MeatDelivery.Application.Validators.Auth
{
    public class LogoutRequestDtoValidator : AbstractValidator<LogoutRequestDto>
    {
        public LogoutRequestDtoValidator()
        {
            RuleFor(x => x.RefreshToken)
                .NotEmpty().WithMessage("Refresh token is required.");
        }
    }
}
