using FluentValidation;
using MeatDelivery.Application.DTOs.Admin;

namespace MeatDelivery.Application.Validators.Admin
{
    public class AdminLoginRequestDtoValidator : AbstractValidator<AdminLoginRequestDto>
    {
        public AdminLoginRequestDtoValidator()
        {
            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email is required.")
                .EmailAddress().WithMessage("A valid email address is required.")
                .MaximumLength(150).WithMessage("Email cannot exceed 150 characters.");

            RuleFor(x => x.Password)
                .NotEmpty().WithMessage("Password is required.")
                .MaximumLength(100).WithMessage("Password cannot exceed 100 characters.");
        }
    }
}
