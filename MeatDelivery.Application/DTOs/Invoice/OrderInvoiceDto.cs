using System;
using System.Collections.Generic;

namespace MeatDelivery.Application.DTOs.Invoice
{
    public class OrderInvoiceDto
    {
        public string InvoiceNo { get; set; } = string.Empty;
        public DateTime InvoiceDate { get; set; }
        
        // Company Information
        public string? CompanyNameEn { get; set; }
        public string? CompanyNameAr { get; set; }
        public string? CompanyAddress { get; set; }
        public string? CompanyPhone { get; set; }
        public string? CompanyEmail { get; set; }

        // Order References
        public long OrderId { get; set; }
        public string OrderDocNo { get; set; } = string.Empty;
        public DateTime PlacedAt { get; set; }
        public string OrderStatus { get; set; } = string.Empty;

        // Customer Details
        public long CustomerUserId { get; set; }
        public string CustomerName { get; set; } = string.Empty;
        public string CustomerPhone { get; set; } = string.Empty;
        public string? CustomerEmail { get; set; }

        // Delivery Address
        public InvoiceAddressDto DeliveryAddress { get; set; } = new();

        // Delivery Schedule
        public InvoiceScheduleDto DeliverySchedule { get; set; } = new();

        // Financial Summary (Without VAT)
        public string CurrencyCode { get; set; } = "AED";
        public decimal Subtotal { get; set; }
        public decimal ProductDiscountTotal { get; set; }
        public long? CouponId { get; set; }
        public decimal CouponDiscount { get; set; }
        public decimal DeliveryCharge { get; set; }
        public decimal TotalAmount { get; set; }

        // Payment Info
        public string PaymentMethod { get; set; } = "COD";
        public string PaymentStatus { get; set; } = "PENDING";

        // Itemized Lines
        public List<InvoiceItemDto> Items { get; set; } = new();
    }

    public class InvoiceAddressDto
    {
        public long AddressId { get; set; }
        public string AddressType { get; set; } = "HOME";
        public string ContactNumber { get; set; } = string.Empty;
        public string BuildingName { get; set; } = string.Empty;
        public string VillaOrFlatNo { get; set; } = string.Empty;
        public string Street { get; set; } = string.Empty;
        public string Area { get; set; } = string.Empty;
        public string Landmark { get; set; } = string.Empty;
        public string City { get; set; } = string.Empty;
        public string Emirate { get; set; } = string.Empty;
        public string PostalCode { get; set; } = string.Empty;
        public decimal Latitude { get; set; }
        public decimal Longitude { get; set; }
    }

    public class InvoiceScheduleDto
    {
        public string DeliveryDate { get; set; } = string.Empty;
        public string StartTime { get; set; } = string.Empty;
        public string EndTime { get; set; } = string.Empty;
    }
}
