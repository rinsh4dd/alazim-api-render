using System;
using System.Collections.Generic;

namespace MeatDelivery.Application.DTOs.Company
{
    public class DeliverySlotsResponseDto
    {
        public DateTime Date { get; set; }
        public string FormattedDate { get; set; } = string.Empty;
        public string DayName { get; set; } = string.Empty;
        public List<DeliverySlotPeriodGroupDto> Periods { get; set; } = new List<DeliverySlotPeriodGroupDto>();
    }
}
