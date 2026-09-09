using System;
using System.Collections.Generic;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Order
{
    public class AdminOrderDetailDto : CustomerOrderDetailDto
    {
        public string CustomerFullName { get; set; } = string.Empty;
        public string CustomerMobileNumber { get; set; } = string.Empty;
        public string? CustomerCountryCode { get; set; }
        public string? CustomerEmail { get; set; }
    }
}
