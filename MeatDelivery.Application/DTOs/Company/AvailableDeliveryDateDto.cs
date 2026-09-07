using System;

namespace MeatDelivery.Application.DTOs.Company
{
    public class AvailableDeliveryDateDto
    {
        public DateTime Date { get; set; }
        public string DayName { get; set; } = string.Empty;
    }
}
