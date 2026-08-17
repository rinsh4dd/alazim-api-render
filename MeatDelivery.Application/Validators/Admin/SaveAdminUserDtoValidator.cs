using FluentValidation;
using MeatDelivery.Application.DTOs.Admin;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.Validators.Admin
{
    public class SaveAdminUserDtoValidator : AbstractValidator<SaveAdminUserDto>
    {
        public SaveAdminUserDtoValidator()
        {
            RuleFor(x => x.Mode)
                .IsInEnum().WithMessage("Invalid admin operation mode.");

            // ADD Mode validations
            When(x => x.Mode == Mode.ADD, () =>
            {
                RuleFor(x => x.Email)
                    .NotEmpty().WithMessage("Email address is required.")
                    .EmailAddress().WithMessage("A valid email address is required.")
                    .MaximumLength(150).WithMessage("Email must not exceed 150 characters.");

                RuleFor(x => x.Password)
                    .NotEmpty().WithMessage("Password is required for new admin creation.")
                    .MinimumLength(8).WithMessage("Password must be at least 8 characters long.")
                    .Matches(@"[A-Z]").WithMessage("Password must contain at least one uppercase letter.")
                    .Matches(@"[a-z]").WithMessage("Password must contain at least one lowercase letter.")
                    .Matches(@"[0-9]").WithMessage("Password must contain at least one numeric digit.")
                    .Matches(@"[\!\?\*\.@#\$%^&+=]").WithMessage("Password must contain at least one special character.");

                RuleFor(x => x.FirstName)
                    .NotEmpty().WithMessage("First name is required.")
                    .MaximumLength(100).WithMessage("First name must not exceed 100 characters.");

                RuleFor(x => x.Role)
                    .NotNull().WithMessage("Role is required for new admin creation.")
                    .IsInEnum().WithMessage("Invalid admin role.");
            });

            // EDIT Mode validations
            When(x => x.Mode == Mode.EDIT, () =>
            {
                RuleFor(x => x.AdminUserId)
                    .NotNull().WithMessage("AdminUserId is required for editing.")
                    .GreaterThan(0).WithMessage("Valid AdminUserId is required.");

                When(x => !string.IsNullOrWhiteSpace(x.Email), () =>
                {
                    RuleFor(x => x.Email)
                        .EmailAddress().WithMessage("A valid email address is required.")
                        .MaximumLength(150).WithMessage("Email must not exceed 150 characters.");
                });

                When(x => !string.IsNullOrWhiteSpace(x.Password), () =>
                {
                    RuleFor(x => x.Password)
                        .MinimumLength(8).WithMessage("Password must be at least 8 characters long.")
                        .Matches(@"[A-Z]").WithMessage("Password must contain at least one uppercase letter.")
                        .Matches(@"[a-z]").WithMessage("Password must contain at least one lowercase letter.")
                        .Matches(@"[0-9]").WithMessage("Password must contain at least one numeric digit.")
                        .Matches(@"[\!\?\*\.@#\$%^&+=]").WithMessage("Password must contain at least one special character.");
                });

                When(x => x.Role.HasValue, () =>
                {
                    RuleFor(x => x.Role!.Value)
                        .IsInEnum().WithMessage("Invalid admin role.");
                });
            });

            // DELETE Mode validations
            When(x => x.Mode == Mode.DELETE, () =>
            {
                RuleFor(x => x.AdminUserId)
                    .NotNull().WithMessage("AdminUserId is required for deletion.")
                    .GreaterThan(0).WithMessage("Valid AdminUserId is required.");
            });
        }
    }
}
