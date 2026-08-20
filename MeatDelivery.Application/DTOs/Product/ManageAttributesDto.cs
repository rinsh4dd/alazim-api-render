using System.Collections.Generic;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Product
{
    public class ManageAttributesDto
    {
        public ProductAttributeMode Mode { get; set; } = ProductAttributeMode.FEATURED;
        public List<long> ProductIds { get; set; } = new();
        public bool Value { get; set; } = true;
    }
}
