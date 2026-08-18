using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Product
{
    public class SaveMeasurementUnitDto
    {
        public Mode Mode { get; set; }
        public int? UnitId { get; set; }
        public string? UnitDescription { get; set; }
        public bool? IsActive { get; set; }
    }
}
