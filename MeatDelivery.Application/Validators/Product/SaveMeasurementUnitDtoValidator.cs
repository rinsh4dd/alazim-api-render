using FluentValidation;
using MeatDelivery.Application.DTOs.Product;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.Validators.Product
{
    public class SaveMeasurementUnitDtoValidator : AbstractValidator<SaveMeasurementUnitDto>
    {
        public SaveMeasurementUnitDtoValidator()
        {
            RuleFor(x => x.Mode)
                .IsInEnum().WithMessage("Invalid operation mode.");

            When(x => x.Mode == Mode.ADD, () =>
            {
                RuleFor(x => x.UnitDescription)
                    .NotEmpty().WithMessage("Unit description is required.")
                    .MaximumLength(50).WithMessage("Unit description must not exceed 50 characters.");
            });

            When(x => x.Mode == Mode.EDIT, () =>
            {
                RuleFor(x => x.UnitId)
                    .NotNull().WithMessage("UnitId is required for edit.")
                    .GreaterThan(0).WithMessage("Valid UnitId is required.");

                When(x => !string.IsNullOrWhiteSpace(x.UnitDescription), () =>
                {
                    RuleFor(x => x.UnitDescription)
                        .MaximumLength(50).WithMessage("Unit description must not exceed 50 characters.");
                });
            });
        }
    }
}
