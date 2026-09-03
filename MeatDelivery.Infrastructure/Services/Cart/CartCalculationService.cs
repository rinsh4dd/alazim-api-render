using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Dapper;
using MeatDelivery.Application.Common.Helpers;
using MeatDelivery.Application.DTOs.Cart;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Cart;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Infrastructure.Services.Cart
{
    public class CartCalculationService : ICartCalculationService
    {
        private readonly ICartRepository _cartRepository;

        public CartCalculationService(ICartRepository cartRepository)
        {
            _cartRepository = cartRepository;
        }

        public async Task<CustomerCartSummaryDto> CalculateActiveCartAsync(long customerUserId, CancellationToken cancellationToken = default)
        {
            var (cartHeader, cartItemRows, optionRows) = await _cartRepository.GetCartRawDataAsync(customerUserId, cancellationToken);
            if (cartHeader == null)
            {
                return CartSummaryHelper.CreateEmptyCartSummary();
            }

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

                // 1. Initial price starts at product base catalog price
                decimal currentPrice = basePrice;

                var itemOptionDtos = new List<CartItemOptionDetailDto>();
                decimal totalOptionExtraPrice = 0.00m;

                if (optionsByCartItem.TryGetValue(cartItemId, out var itemOptions))
                {
                    // Sequential Order Pipeline: FIXED_PRICE -> MULTIPLIER -> PERCENTAGE -> ADDITIONAL_PRICE
                    var sortedOptions = itemOptions
                        .OrderBy(o => GetPricingPrecedence(ParsePricingType((string?)o.PRICING_TYPE)))
                        .ToList();

                    foreach (var opt in sortedOptions)
                    {
                        PricingType pricingType = ParsePricingType((string?)opt.PRICING_TYPE);

                        // Typed SelectedValue (e.g. 1.350 KG) takes precedence over Option PricingValue (e.g. 1.000 KG)
                        decimal val = opt.SELECTED_VALUE != null
                            ? Convert.ToDecimal(opt.SELECTED_VALUE)
                            : Convert.ToDecimal(opt.PRICING_VALUE);

                        decimal previousPrice = currentPrice;
                        currentPrice = ApplyPricing(currentPrice, pricingType, val);
                        decimal optionDelta = currentPrice - previousPrice;

                        totalOptionExtraPrice += optionDelta;

                        decimal? selectedVal = opt.SELECTED_VALUE != null ? Convert.ToDecimal(opt.SELECTED_VALUE) : null;
                        decimal pricingVal = Convert.ToDecimal(opt.PRICING_VALUE);

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
                            PricingValue = pricingVal,
                            SelectedValue = selectedVal,
                            IsCustomDataAllowed = Convert.ToBoolean(opt.IS_CUSTOM_DATA_ALLOWED ?? false),
                            OptionPrice = optionDelta
                        });
                    }
                }

                decimal unitPrice = basePrice;
                decimal configuredUnitPrice = currentPrice;
                decimal lineTotalPrice = configuredUnitPrice * quantity;

                cartSubtotal += lineTotalPrice;
                totalItemCount += quantity;

                itemDetailList.Add(new CartItemDetailDto
                {
                    CartItemId = cartItemId,
                    ProductId = (long)itemRow.PRODUCT_ID,
                    ProductNameEn = (string)(itemRow.PRODUCT_NAME_EN ?? string.Empty),
                    ProductNameAr = (string)(itemRow.PRODUCT_NAME_AR ?? string.Empty),
                    ProductImage = (string?)itemRow.PRODUCT_IMAGE,
                    UnitDescription = (string?)itemRow.UNIT_DESCRIPTION,
                    Quantity = quantity,
                    SpecialInstructions = (string?)itemRow.SPECIAL_INSTRUCTIONS,
                    UnitPrice = unitPrice,
                    TotalCustomizationExtraPrice = totalOptionExtraPrice,
                    LineTotalPrice = lineTotalPrice,
                    CustomizationOptions = itemOptionDtos
                });
            }

            decimal discountAmount = 0.00m;
            decimal deliveryFee = 0.00m;
            decimal grandTotal = cartSubtotal - discountAmount + deliveryFee;

            return new CustomerCartSummaryDto
            {
                CartId = (long)cartHeader.CART_ID,
                CartStatus = (string)(cartHeader.CART_STATUS ?? "ACTIVE"),
                TotalItemCount = totalItemCount,
                Summary = new CartPricingSummaryDto
                {
                    Subtotal = cartSubtotal,
                    DiscountAmount = discountAmount,
                    DiscountedSubtotal = cartSubtotal - discountAmount,
                    DeliveryCharge = deliveryFee,
                    GrandTotal = grandTotal,
                    IsFreeDelivery = true
                },
                Items = itemDetailList
            };
        }

        // --- SEQUENTIAL PRICING PIPELINE TRANSFORMER ---
        private static decimal ApplyPricing(decimal currentPrice, PricingType pricingType, decimal val)
        {
            return pricingType switch
            {
                PricingType.FIXED_PRICE => val > 0 ? val : currentPrice,
                PricingType.MULTIPLIER => val > 0 ? currentPrice * val : currentPrice,
                PricingType.PERCENTAGE => currentPrice + (currentPrice * (val / 100.00m)),
                PricingType.ADDITIONAL_PRICE => currentPrice + val,
                _ => currentPrice + val
            };
        }

        // --- PRICING PRECEDENCE ORDER ---
        private static int GetPricingPrecedence(PricingType pricingType)
        {
            return pricingType switch
            {
                PricingType.FIXED_PRICE => 1,
                PricingType.MULTIPLIER => 2,
                PricingType.PERCENTAGE => 3,
                PricingType.ADDITIONAL_PRICE => 4,
                _ => 5
            };
        }

        private static PricingType ParsePricingType(string? pricingTypeStr)
        {
            if (Enum.TryParse<PricingType>(pricingTypeStr, true, out var result))
            {
                return result;
            }
            return PricingType.ADDITIONAL_PRICE;
        }
    }
}
