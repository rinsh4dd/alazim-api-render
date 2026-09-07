using System.Collections.Generic;

namespace MeatDelivery.Application.DTOs.Company
{
    public class DeliverySlotPeriodGroupDto
    {
        public string PeriodName { get; set; } = string.Empty;
        public List<DeliverySlotDto> Slots { get; set; } = new List<DeliverySlotDto>();
    }
}
