using System.Collections.Generic;

namespace MeatDelivery.Application.DTOs.Product
{
    public class ManageAttributesDto
    {
        public string Mode { get; set; } = string.Empty;
        public List<long> ProductIds { get; set; } = new();
        public bool Value { get; set; } = true;
    }
}
