using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using Dapper;
using MeatDelivery.Application.DTOs.Cart;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Cart;

namespace MeatDelivery.Infrastructure.Services.Cart
{
    public class CartCalculationService : ICartCalculationService
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public CartCalculationService(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<CustomerCartSummaryDto> CalculateActiveCartAsync(long customerUserId, CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();

            using var gridReader = await connection.QueryMultipleAsync(
                "dbo.PR_GET_CUSTOMER_ACTIVE_CART",
                new { CUSTOMER_USER_ID = customerUserId },
                commandType: CommandType.StoredProcedure
            );

            var cartHeader = (await gridReader.ReadAsync<dynamic>()).FirstOrDefault();
            if (cartHeader == null)
            {
                return CreateEmptyCartSummary();
            }

            var cartItemRows = (await gridReader.ReadAsync<dynamic>()).ToList();
            var optionRows = (await gridReader.ReadAsync<dynamic>()).ToList();

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
                string? customData = (string?)itemRow.CUSTOM_DATA;

                // 1. Process Customization Options & Extra Prices
                var itemOptionDtos = new List<CartItemOptionDetailDto>();
                decimal itemExtraPrice = 0.00m;

                if (optionsByCartItem.TryGetValue(cartItemId, out var itemOptions))
                {
                    foreach (var opt in itemOptions)
                    {
                        string pricingType = (string)(opt.PRICING_TYPE ?? "ADDITIONAL_PRICE").ToString().ToUpperInvariant();
                        decimal val = Convert.ToDecimal(opt.ADDITIONAL_PRICE ?? 0);
                        decimal optionPrice = CalculateOptionPrice(pricingType, val, basePrice);

                        itemExtraPrice += optionPrice;

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
                            OptionPrice = optionPrice
                        });
                    }
                }

                // 2. Parse Custom Weight & Calculate Line Total
                decimal weightMultiplier = ParseWeightMultiplier(customData);
                decimal unitPrice = basePrice;
                decimal itemBaseTotal = basePrice * weightMultiplier;
                decimal lineTotalPrice = (itemBaseTotal + itemExtraPrice) * quantity;

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
                    CustomData = customData,
                    SpecialInstructions = (string?)itemRow.SPECIAL_INSTRUCTIONS,
                    UnitPrice = unitPrice,
                    TotalCustomizationExtraPrice = itemExtraPrice,
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

        private static decimal CalculateOptionPrice(string pricingType, decimal val, decimal basePrice)
        {
            return pricingType switch
            {
                "MULTIPLIER" => val > 0 ? basePrice * (val - 1.00m) : 0.00m,
                "PERCENTAGE" => basePrice * (val / 100.00m),
                "FIXED_PRICE" => val,
                _ => val // ADDITIONAL_PRICE
            };
        }

        private static decimal ParseWeightMultiplier(string? customData)
        {
            if (string.IsNullOrWhiteSpace(customData)) return 1.00m;

            var match = Regex.Match(customData, @"\d+(\.\d+)?");
            if (match.Success && decimal.TryParse(match.Value, NumberStyles.Any, CultureInfo.InvariantCulture, out decimal weight) && weight > 0)
            {
                return weight;
            }

            return 1.00m;
        }

        private static CustomerCartSummaryDto CreateEmptyCartSummary()
        {
            return new CustomerCartSummaryDto
            {
                CartId = 0,
                CartStatus = "ACTIVE",
                TotalItemCount = 0,
                Summary = new CartPricingSummaryDto
                {
                    Subtotal = 0.00m,
                    DiscountAmount = 0.00m,
                    DiscountedSubtotal = 0.00m,
                    DeliveryCharge = 0.00m,
                    GrandTotal = 0.00m,
                    IsFreeDelivery = true
                },
                Items = new List<CartItemDetailDto>()
            };
        }
    }
}
