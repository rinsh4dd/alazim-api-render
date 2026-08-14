using FluentValidation;
using MeatDelivery.Application.DTOs.Addresses;

namespace MeatDelivery.Application.Validators.Addresses
{
    public class UpdateCustomerAddressDtoValidator : AbstractValidator<UpdateCustomerAddressDto>
    {
        public UpdateCustomerAddressDtoValidator()
        {
            RuleFor(x => x.AddressLabel)
                .NotEmpty().WithMessage("Address label is required (e.g. Home, Work, Villa).")
                .MaximumLength(100).WithMessage("Address label cannot exceed 100 characters.");

            RuleFor(x => x.Emirate)
                .NotEmpty().WithMessage("Emirate is required (e.g. Dubai, Abu Dhabi, Sharjah).")
                .MaximumLength(100).WithMessage("Emirate cannot exceed 100 characters.");

            RuleFor(x => x.Area)
                .NotEmpty().WithMessage("Area is required.")
                .MaximumLength(150).WithMessage("Area cannot exceed 150 characters.");

            RuleFor(x => x.BuildingName)
                .MaximumLength(150).WithMessage("Building name cannot exceed 150 characters.");

            RuleFor(x => x.VillaApartmentNo)
                .MaximumLength(50).WithMessage("Villa/Apartment number cannot exceed 50 characters.");

            RuleFor(x => x.FloorNo)
                .MaximumLength(50).WithMessage("Floor number cannot exceed 50 characters.");

            RuleFor(x => x.Landmark)
                .MaximumLength(250).WithMessage("Landmark cannot exceed 250 characters.");

            RuleFor(x => x.PostalCode)
                .MaximumLength(5).WithMessage("Postal code cannot exceed 5 characters.")
                .Matches(@"^[0-9]{5}$")
                .When(x => !string.IsNullOrWhiteSpace(x.PostalCode))
                .WithMessage("Postal code must be a valid 5-digit number (e.g. 12345).");

            RuleFor(x => x.DeliveryNotes)
                .MaximumLength(500).WithMessage("Delivery notes cannot exceed 500 characters.");

            RuleFor(x => x.Latitude)
                .InclusiveBetween(-90m, 90m).When(x => x.Latitude.HasValue)
                .WithMessage("Latitude must be between -90 and 90.");

            RuleFor(x => x.Longitude)
                .InclusiveBetween(-180m, 180m).When(x => x.Longitude.HasValue)
                .WithMessage("Longitude must be between -180 and 180.");
        }
    }
}
