using System;
using FluentValidation;
using MeatDelivery.Application.DTOs.Offer;

namespace MeatDelivery.Application.Validators.Offer
{
    public class SaveOfferDtoValidator : AbstractValidator<SaveOfferDto>
    {
        public SaveOfferDtoValidator()
        {
            RuleFor(x => x.Mode)
                .NotEmpty()
                .Must(m => m.Equals("ADD", StringComparison.OrdinalIgnoreCase) ||
                           m.Equals("EDIT", StringComparison.OrdinalIgnoreCase) ||
                           m.Equals("DELETE", StringComparison.OrdinalIgnoreCase))
                .WithMessage("Mode must be ADD, EDIT, or DELETE.");

            When(x => x.Mode.Equals("EDIT", StringComparison.OrdinalIgnoreCase) ||
                      x.Mode.Equals("DELETE", StringComparison.OrdinalIgnoreCase), () =>
            {
                RuleFor(x => x.OfferId)
                    .GreaterThan(0)
                    .WithMessage("OfferId is required for EDIT or DELETE mode.");
            });

            When(x => !x.Mode.Equals("DELETE", StringComparison.OrdinalIgnoreCase), () =>
            {
                RuleFor(x => x.OfferTitleEn)
                    .NotEmpty()
                    .MaximumLength(200)
                    .WithMessage("English offer title is required and cannot exceed 200 characters.");

                RuleFor(x => x.OfferTitleAr)
                    .NotEmpty()
                    .MaximumLength(200)
                    .WithMessage("Arabic offer title is required and cannot exceed 200 characters.");

                RuleFor(x => x.DiscountType)
                    .NotEmpty()
                    .Must(t => t.Equals("FLAT", StringComparison.OrdinalIgnoreCase) ||
                               t.Equals("PERCENTAGE", StringComparison.OrdinalIgnoreCase) ||
                               t.Equals("FIXED_AMOUNT", StringComparison.OrdinalIgnoreCase))
                    .WithMessage("DiscountType must be FLAT or PERCENTAGE.");

                RuleFor(x => x.DiscountValue)
                    .GreaterThan(0)
                    .WithMessage("DiscountValue must be greater than 0.");

                RuleFor(x => x.EndAt)
                    .GreaterThan(x => x.StartAt)
                    .WithMessage("EndAt must be after StartAt.");
            });
        }
    }
}
