using FluentValidation;
using MeatDelivery.Application.DTOs.Company;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.Validators.Company
{
    public class SaveCompanyHolidayDtoValidator : AbstractValidator<SaveCompanyHolidayDto>
    {
        public SaveCompanyHolidayDtoValidator()
        {
            RuleFor(x => x.Mode)
                .IsInEnum().WithMessage("Invalid operation mode.");

            RuleFor(x => x.CompanyConfigId)
                .GreaterThan(0).WithMessage("Valid CompanyConfigId is required.");

            When(x => x.Mode == Mode.ADD, () =>
            {
                RuleFor(x => x.HolidayDate)
                    .NotEmpty().WithMessage("HolidayDate is required.");

                RuleFor(x => x.HolidayType)
                    .NotEmpty().WithMessage("HolidayType is required.")
                    .MaximumLength(50).WithMessage("HolidayType cannot exceed 50 characters.");
            });

            When(x => x.Mode == Mode.EDIT, () =>
            {
                RuleFor(x => x.CompanyHolidayId)
                    .NotNull().WithMessage("CompanyHolidayId is required for EDIT mode.")
                    .GreaterThan(0).WithMessage("Valid CompanyHolidayId is required for EDIT mode.");

                RuleFor(x => x.HolidayDate)
                    .NotEmpty().WithMessage("HolidayDate is required.");
            });

            When(x => x.Mode == Mode.DELETE, () =>
            {
                RuleFor(x => x.CompanyHolidayId)
                    .NotNull().WithMessage("CompanyHolidayId is required for DELETE mode.")
                    .GreaterThan(0).WithMessage("Valid CompanyHolidayId is required for DELETE mode.");
            });

            When(x => !string.IsNullOrWhiteSpace(x.ReasonEn), () =>
            {
                RuleFor(x => x.ReasonEn)
                    .MaximumLength(250).WithMessage("ReasonEn cannot exceed 250 characters.");
            });

            When(x => !string.IsNullOrWhiteSpace(x.ReasonAr), () =>
            {
                RuleFor(x => x.ReasonAr)
                    .MaximumLength(250).WithMessage("ReasonAr cannot exceed 250 characters.");
            });
        }
    }
}
