using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.Common.Helpers;
using MeatDelivery.Application.DTOs.Cart;
using MeatDelivery.Application.DTOs.Coupon;
using MeatDelivery.Application.DTOs.Offer;
using MeatDelivery.Application.Interfaces.Cart;
using MeatDelivery.Application.Interfaces.Repositories.Offer;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Infrastructure.Services.Cart
{
    public class CartCalculationService : ICartCalculationService
    {
        private readonly ICartRepository _cartRepository;
        private readonly IOfferRepository _offerRepository;

        public CartCalculationService(ICartRepository cartRepository, IOfferRepository offerRepository)
        {
            _cartRepository = cartRepository;
            _offerRepository = offerRepository;
        }

        public async Task<CustomerCartSummaryDto> CalculateActiveCartAsync(long customerUserId, CancellationToken cancellationToken = default)
        {
            var (cartHeader, cartItemRows, optionRows) = await _cartRepository.GetCartRawDataAsync(customerUserId, cancellationToken);
            if (cartHeader == null)
            {
                return CartSummaryHelper.CreateEmptyCartSummary();
            }

            // Fetch all currently active offers once — shared across all cart item resolution
            var activeOffers = (await _offerRepository.GetActiveOffersAsync(cancellationToken)).ToList();

            var optionsByCartItem = optionRows
                .GroupBy(o => (long)o.CART_ITEM_ID)
                .ToDictionary(g => g.Key, g => g.ToList());

            var itemDetailList = new List<CartItemDetailDto>();
            decimal cartSubtotal = 0.00m;
            int totalItemCount = 0;

            foreach (var itemRow in cartItemRows)
            {
                long cartItemId = (long)itemRow.CART_ITEM_ID;
                decimal basePrice = Convert.ToDecimal(itemRow.BASE_PRICE ?? 0);
                int quantity = (int)itemRow.QUANTITY;

                decimal currentPrice = basePrice;
                var itemOptionDtos = new List<CartItemOptionDetailDto>();
                decimal totalOptionExtraPrice = 0.00m;

                if (optionsByCartItem.TryGetValue(cartItemId, out var itemOptions))
                {
                    var sortedOptions = itemOptions
                        .OrderBy(o => GetPricingPrecedence(ParsePricingType((string?)o.PRICING_TYPE)))
                        .ToList();

                    foreach (var opt in sortedOptions)
                    {
                        var pricingType = ParsePricingType((string?)opt.PRICING_TYPE);
                        decimal val = opt.SELECTED_VALUE != null
                            ? Convert.ToDecimal(opt.SELECTED_VALUE)
                            : Convert.ToDecimal(opt.PRICING_VALUE);

                        decimal previousPrice = currentPrice;
                        currentPrice = ApplyPricing(currentPrice, pricingType, val);
                        decimal optionDelta = currentPrice - previousPrice;

                        totalOptionExtraPrice += optionDelta;

                        itemOptionDtos.Add(new CartItemOptionDetailDto
                        {
                            CustomizationOptionId = (long)opt.CUSTOMIZATION_OPTION_ID,
                            CustomizationGroupId = (long)opt.CUSTOMIZATION_GROUP_ID,
                            GroupNameEn = (string)(opt.GROUP_NAME_EN ?? string.Empty),
                            GroupNameAr = (string)(opt.GROUP_NAME_AR ?? string.Empty),
                            OptionCode = (string)(opt.OPTION_CODE ?? string.Empty),
                            OptionNameEn = (string)(opt.OPTION_NAME_EN ?? string.Empty),
                            OptionNameAr = (string)(opt.OPTION_NAME_AR ?? string.Empty),
                            PricingType = pricingType,
                            PricingValue = Convert.ToDecimal(opt.PRICING_VALUE),
                            SelectedValue = opt.SELECTED_VALUE != null ? Convert.ToDecimal(opt.SELECTED_VALUE) : null,
                            IsCustomDataAllowed = Convert.ToBoolean(opt.IS_CUSTOM_DATA_ALLOWED ?? false),
                            OptionPrice = optionDelta
                        });
                    }
                }

                decimal configuredUnitPrice = currentPrice;

                // ── Offer Resolution per cart item ────────────────────────────
                long productId  = (long)itemRow.PRODUCT_ID;
                long categoryId = itemRow.CATEGORY_ID != null ? (long)itemRow.CATEGORY_ID : 0L;
                var bestOffer   = ResolveBestOffer(activeOffers, productId, categoryId, configuredUnitPrice);

                // Apply offer price only when it yields a lower unit price
                decimal effectiveUnitPrice = bestOffer != null
                    ? Math.Min(configuredUnitPrice, bestOffer.EffectiveUnitPrice)
                    : configuredUnitPrice;

                decimal lineTotalPrice = effectiveUnitPrice * quantity;

                cartSubtotal += lineTotalPrice;
                totalItemCount += quantity;

                itemDetailList.Add(new CartItemDetailDto
                {
                    CartItemId = cartItemId,
                    ProductId = productId,
                    ProductNameEn = (string)(itemRow.PRODUCT_NAME_EN ?? string.Empty),
                    ProductNameAr = (string)(itemRow.PRODUCT_NAME_AR ?? string.Empty),
                    ProductImage = (string?)itemRow.PRODUCT_IMAGE,
                    UnitDescription = (string?)itemRow.UNIT_DESCRIPTION,
                    Quantity = quantity,
                    SpecialInstructions = (string?)itemRow.SPECIAL_INSTRUCTIONS,
                    UnitPrice = basePrice,
                    TotalCustomizationExtraPrice = totalOptionExtraPrice,
                    AppliedOfferId = bestOffer?.OfferId,
                    AppliedOfferTitleEn = bestOffer?.OfferTitleEn,
                    OfferUnitPrice = bestOffer != null ? effectiveUnitPrice : null,
                    LineTotalPrice = lineTotalPrice,
                    CustomizationOptions = itemOptionDtos
                });
            }

            AppliedCouponDto? appliedCoupon = null;
            decimal discountAmount = 0.00m;

            if (cartHeader.COUPON_ID != null && !string.IsNullOrWhiteSpace((string?)cartHeader.COUPON_CODE))
            {
                var minOrder = cartHeader.MINIMUM_ORDER_AMOUNT != null ? Convert.ToDecimal(cartHeader.MINIMUM_ORDER_AMOUNT) : 0.00m;
                if (cartSubtotal >= minOrder)
                {
                    appliedCoupon = new AppliedCouponDto
                    {
                        CouponId = (long)cartHeader.COUPON_ID,
                        CouponCode = (string)cartHeader.COUPON_CODE,
                        CouponName = (string)cartHeader.COUPON_NAME,
                        DiscountType = (string)cartHeader.DISCOUNT_TYPE,
                        DiscountValue = Convert.ToDecimal(cartHeader.DISCOUNT_VALUE),
                        MaxDiscountAmount = cartHeader.MAX_DISCOUNT_AMOUNT != null ? Convert.ToDecimal(cartHeader.MAX_DISCOUNT_AMOUNT) : null,
                        MinimumOrderAmount = minOrder
                    };

                    var parsedDiscountType = ParseDiscountType(appliedCoupon.DiscountType);

                    if (parsedDiscountType == DiscountType.PERCENTAGE)
                    {
                        discountAmount = cartSubtotal * (appliedCoupon.DiscountValue / 100.00m);
                        if (appliedCoupon.MaxDiscountAmount.HasValue && discountAmount > appliedCoupon.MaxDiscountAmount.Value)
                        {
                            discountAmount = appliedCoupon.MaxDiscountAmount.Value;
                        }
                    }
                    else if (parsedDiscountType == DiscountType.FLAT)
                    {
                        discountAmount = appliedCoupon.DiscountValue;
                        if (discountAmount > cartSubtotal)
                        {
                            discountAmount = cartSubtotal;
                        }
                    }
                }
            }

            return BuildCartSummaryResponse(cartHeader, totalItemCount, cartSubtotal, itemDetailList, appliedCoupon, discountAmount);
        }

        /// <summary>
        /// Resolves the single best active offer for a product using scope precedence:
        /// PRODUCT (1) > CATEGORY (2) > ALL (3). Tie-broken by lowest effective price.
        /// </summary>
        private static ResolvedOffer? ResolveBestOffer(
            IEnumerable<ActiveOfferDto> activeOffers,
            long productId,
            long categoryId,
            decimal baseUnitPrice)
        {
            ResolvedOffer? best = null;

            foreach (var offer in activeOffers)
            {
                foreach (var scope in offer.Scopes)
                {
                    bool matches = scope.ScopeType?.ToUpperInvariant() switch
                    {
                        "ALL"      => true,
                        "CATEGORY" => scope.CategoryId.HasValue && scope.CategoryId.Value == categoryId,
                        "PRODUCT"  => scope.ProductId.HasValue  && scope.ProductId.Value  == productId,
                        _          => false
                    };

                    if (!matches) continue;

                    int scopePrecedence = scope.ScopeType?.ToUpperInvariant() switch
                    {
                        "PRODUCT"  => 1,
                        "CATEGORY" => 2,
                        _          => 3
                    };

                    decimal effectivePrice = offer.DiscountType?.ToUpperInvariant() == "PERCENTAGE"
                        ? baseUnitPrice - (baseUnitPrice * (offer.DiscountValue / 100m))
                        : baseUnitPrice - offer.DiscountValue;

                    if (effectivePrice < 0m) effectivePrice = 0m;

                    if (best == null
                        || scopePrecedence < best.ScopePrecedence
                        || (scopePrecedence == best.ScopePrecedence && effectivePrice < best.EffectiveUnitPrice))
                    {
                        best = new ResolvedOffer
                        {
                            OfferId          = offer.OfferId,
                            OfferTitleEn     = offer.OfferTitleEn,
                            ScopePrecedence  = scopePrecedence,
                            EffectiveUnitPrice = effectivePrice
                        };
                    }

                    break; // one matching scope per offer is enough
                }
            }

            return best;
        }

        private sealed class ResolvedOffer
        {
            public long   OfferId           { get; init; }
            public string OfferTitleEn      { get; init; } = string.Empty;
            public int    ScopePrecedence   { get; init; }
            public decimal EffectiveUnitPrice { get; init; }
        }



        private static CustomerCartSummaryDto BuildCartSummaryResponse(
            dynamic cartHeader,
            int totalItemCount,
            decimal cartSubtotal,
            List<CartItemDetailDto> itemDetailList,
            AppliedCouponDto? appliedCoupon = null,
            decimal discountAmount = 0.00m,
            decimal deliveryFee = 0.00m)
        {
            var grandTotal = cartSubtotal - discountAmount + deliveryFee;

            return new CustomerCartSummaryDto
            {
                CartId = (long)cartHeader.CART_ID,
                CartStatus = (string)cartHeader.CART_STATUS,
                TotalItemCount = totalItemCount,
                AppliedCoupon = appliedCoupon,
                Summary = new CartPricingSummaryDto
                {
                    Subtotal = cartSubtotal,
                    DiscountAmount = discountAmount,
                    DiscountedSubtotal = cartSubtotal - discountAmount,
                    DeliveryCharge = deliveryFee,
                    GrandTotal = grandTotal < 0 ? 0.00m : grandTotal,
                    IsFreeDelivery = deliveryFee == 0.00m
                },
                Items = itemDetailList
            };
        }

        private static decimal ApplyPricing(decimal currentPrice, PricingType pricingType, decimal val) =>
            pricingType switch
            {
                PricingType.FIXED_PRICE => val > 0 ? val : currentPrice,
                PricingType.MULTIPLIER => val > 0 ? currentPrice * val : currentPrice,
                PricingType.PERCENTAGE => currentPrice + (currentPrice * (val / 100.00m)),
                PricingType.ADDITIONAL_PRICE => currentPrice + val,
                _ => currentPrice + val
            };

        private static int GetPricingPrecedence(PricingType pricingType) =>
            pricingType switch
            {
                PricingType.FIXED_PRICE => 1,
                PricingType.MULTIPLIER => 2,
                PricingType.PERCENTAGE => 3,
                PricingType.ADDITIONAL_PRICE => 4,
                _ => 5
            };

        private static PricingType ParsePricingType(string? pricingTypeStr) =>
            Enum.TryParse<PricingType>(pricingTypeStr, true, out var result) ? result : PricingType.ADDITIONAL_PRICE;

        private static DiscountType? ParseDiscountType(string? discountTypeStr) =>
            string.Equals(discountTypeStr, "FIXED_AMOUNT", StringComparison.OrdinalIgnoreCase) ? DiscountType.FLAT :
            Enum.TryParse<DiscountType>(discountTypeStr, true, out var result) ? result : null;
    }
}
