using System;
using System.Collections.Generic;

namespace MeatDelivery.Application.DTOs.Cart
{
    public class CustomerCartDto
    {
        public long? CartId { get; set; }
        public string? DocType { get; set; } = "CRT1";
        public string? DocNo { get; set; }
        public long CustomerUserId { get; set; }
        public string CartStatus { get; set; } = "ACTIVE";
        public long? CouponId { get; set; }
        public DateTime? CreatedAt { get; set; }

        public List<CartItemDto> Items { get; set; } = new List<CartItemDto>();
        public CartPricingSummaryDto PricingSummary { get; set; } = new CartPricingSummaryDto();
    }
}
