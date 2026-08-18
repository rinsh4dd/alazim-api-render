using System;

namespace MeatDelivery.Domain.Entities.Catalog
{
    public class MeasurementUnit
    {
        public int UnitId { get; set; }
        public string Unit { get; set; } = string.Empty;
        public string UnitDescription { get; set; } = string.Empty;
        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
