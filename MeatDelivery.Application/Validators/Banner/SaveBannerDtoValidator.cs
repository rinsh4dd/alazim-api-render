using FluentValidation;
using MeatDelivery.Application.DTOs.Banner;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.Validators.Banner;

public class SaveBannerDtoValidator : AbstractValidator<SaveBannerDto>
{
    public SaveBannerDtoValidator()
    {
        RuleFor(x => x.Mode)
            .NotEmpty().WithMessage("Mode is required.")
            .Must(m => m.Equals("ADD", StringComparison.OrdinalIgnoreCase) ||
                       m.Equals("EDIT", StringComparison.OrdinalIgnoreCase) ||
                       m.Equals("DELETE", StringComparison.OrdinalIgnoreCase))
            .WithMessage("Mode must be ADD, EDIT, or DELETE.");

        When(x => x.Mode.Equals("DELETE", StringComparison.OrdinalIgnoreCase), () =>
        {
            RuleFor(x => x.BannerId)
                .NotNull().GreaterThan(0).WithMessage("BannerId is required for DELETE mode.");
        });

        When(x => !x.Mode.Equals("DELETE", StringComparison.OrdinalIgnoreCase), () =>
        {
            When(x => x.Mode.Equals("ADD", StringComparison.OrdinalIgnoreCase), () =>
            {
                RuleFor(x => x.ImageUrl)
                    .NotEmpty().WithMessage("ImageUrl is required.");
            });

            RuleFor(x => x.EndAt)
                .GreaterThan(x => x.StartAt).WithMessage("End time must be later than start time.");

            RuleFor(x => x.LinkType)
                .NotEmpty().WithMessage("LinkType is required.")
                .Must(lt => lt.Equals(BannerLinkType.None, StringComparison.OrdinalIgnoreCase) ||
                            lt.Equals(BannerLinkType.Product, StringComparison.OrdinalIgnoreCase) ||
                            lt.Equals(BannerLinkType.Category, StringComparison.OrdinalIgnoreCase) ||
                            lt.Equals(BannerLinkType.Offer, StringComparison.OrdinalIgnoreCase) ||
                            lt.Equals(BannerLinkType.External, StringComparison.OrdinalIgnoreCase))
                .WithMessage("LinkType must be NONE, PRODUCT, CATEGORY, OFFER, or EXTERNAL.");

            When(x => x.LinkType.Equals(BannerLinkType.Product, StringComparison.OrdinalIgnoreCase), () =>
            {
                RuleFor(x => x.ProductId)
                    .NotNull().GreaterThan(0).WithMessage("ProductId is required for PRODUCT link type.");
            });

            When(x => x.LinkType.Equals(BannerLinkType.Category, StringComparison.OrdinalIgnoreCase), () =>
            {
                RuleFor(x => x.CategoryId)
                    .NotNull().GreaterThan(0).WithMessage("CategoryId is required for CATEGORY link type.");
            });

            When(x => x.LinkType.Equals(BannerLinkType.Offer, StringComparison.OrdinalIgnoreCase), () =>
            {
                RuleFor(x => x.OfferId)
                    .NotNull().GreaterThan(0).WithMessage("OfferId is required for OFFER link type.");
            });

            When(x => x.LinkType.Equals(BannerLinkType.External, StringComparison.OrdinalIgnoreCase), () =>
            {
                RuleFor(x => x.ExternalUrl)
                    .NotEmpty().WithMessage("ExternalUrl is required for EXTERNAL link type.");
            });
        });
    }
}
