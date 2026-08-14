using FluentValidation;
using MeatDelivery.Application.DTOs.Addresses;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.Validators.Addresses
{
    public class SaveCustomerAddressDtoValidator : AbstractValidator<SaveCustomerAddressDto>
    {
        public SaveCustomerAddressDtoValidator()
        {
            RuleFor(x => x.Mode)
                .IsInEnum().WithMessage("Invalid address mode. Allowed values: ADD, EDIT, DELETE.");

            // AddressId is required for EDIT and DELETE modes
            RuleFor(x => x.AddressId)
                .NotNull().GreaterThan(0).WithMessage("Address ID is required for EDIT and DELETE.")
                .When(x => x.Mode == AddressMode.EDIT || x.Mode == AddressMode.DELETE);

            // Validation rules for ADD and EDIT modes
            When(x => x.Mode == AddressMode.ADD || x.Mode == AddressMode.EDIT, () =>
            {
                RuleFor(x => x.AddressType)
                    .NotNull().WithMessage("Address type is required.")
                    .IsInEnum().WithMessage("Invalid address type. Allowed values: HOME, OFFICE, OTHER.");

                RuleFor(x => x.ContactNumber)
                    .NotEmpty().WithMessage("Contact number is required.")
                    .Matches(@"^\+?\d{7,15}$").WithMessage("Contact number must be between 7 and 15 digits.");

                RuleFor(x => x.VillaOrFlatNo)
                    .NotEmpty().WithMessage("Villa or Flat number is required.")
                    .MaximumLength(50).WithMessage("Villa or Flat number cannot exceed 50 characters.");

                RuleFor(x => x.Street)
                    .NotEmpty().WithMessage("Street is required.")
                    .MaximumLength(150).WithMessage("Street cannot exceed 150 characters.");

                RuleFor(x => x.Area)
                    .NotEmpty().WithMessage("Area is required.")
                    .MaximumLength(150).WithMessage("Area cannot exceed 150 characters.");

                RuleFor(x => x.City)
                    .NotEmpty().WithMessage("City is required.")
                    .MaximumLength(100).WithMessage("City cannot exceed 100 characters.");

                RuleFor(x => x.Emirate)
                    .NotEmpty().WithMessage("Emirate is required.")
                    .MaximumLength(100).WithMessage("Emirate cannot exceed 100 characters.");

                RuleFor(x => x.BuildingName)
                    .MaximumLength(150).WithMessage("Building name cannot exceed 150 characters.");

                RuleFor(x => x.Landmark)
                    .MaximumLength(200).WithMessage("Landmark cannot exceed 200 characters.");

                // 📮 Postal Code Validation (Optional, but strictly validated when provided)
                RuleFor(x => x.PostalCode)
                    .MaximumLength(20).WithMessage("Postal code cannot exceed 20 characters.")
                    .Matches(@"^[a-zA-Z0-9\s\-]{3,20}$")
                    .When(x => !string.IsNullOrWhiteSpace(x.PostalCode))
                    .WithMessage("Postal code must be a valid format (e.g. 12345, PO BOX 100).");

                RuleFor(x => x.Latitude)
                    .InclusiveBetween(-90m, 90m).When(x => x.Latitude.HasValue)
                    .WithMessage("Latitude must be between -90 and 90.");

                RuleFor(x => x.Longitude)
                    .InclusiveBetween(-180m, 180m).When(x => x.Longitude.HasValue)
                    .WithMessage("Longitude must be between -180 and 180.");
            });
        }
    }
}
