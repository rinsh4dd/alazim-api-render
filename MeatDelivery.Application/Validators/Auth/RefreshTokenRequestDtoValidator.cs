using FluentValidation;
using MeatDelivery.Application.DTOs.Auth;

namespace MeatDelivery.Application.Validators.Auth
{
    public class RefreshTokenRequestDtoValidator : AbstractValidator<RefreshTokenRequestDto>
    {
        public RefreshTokenRequestDtoValidator()
        {
            RuleFor(x => x.RefreshToken)
                .NotEmpty().WithMessage("Refresh token is required.");
        }
    }
}
