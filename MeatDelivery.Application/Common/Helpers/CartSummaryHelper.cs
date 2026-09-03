using System.Collections.Generic;
using MeatDelivery.Application.DTOs.Cart;

namespace MeatDelivery.Application.Common.Helpers
{
    public static class CartSummaryHelper
    {
        public static CustomerCartSummaryDto CreateEmptyCartSummary()
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
