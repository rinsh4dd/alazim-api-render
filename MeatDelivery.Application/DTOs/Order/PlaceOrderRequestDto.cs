using System;
using System.ComponentModel.DataAnnotations;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Order
{
    public class PlaceOrderRequestDto
    {
        [Required]
        public long AddressId { get; set; }

        [Required]
        public DateOnly DeliveryDate { get; set; }

        [Required]
        public TimeSpan DeliverySlotStartTime { get; set; }

        [Required]
        public TimeSpan DeliverySlotEndTime { get; set; }

        [Required]
        public PaymentMethod PaymentMethod { get; set; } = PaymentMethod.COD;

        public string? DeliveryInstructions { get; set; }
    }
}
