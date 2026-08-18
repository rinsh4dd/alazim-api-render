namespace MeatDelivery.Application.DTOs.Product
{
    public class MeasurementUnitDto
    {
        public int UnitId { get; set; }
        public string Unit { get; set; } = string.Empty;
        public string UnitDescription { get; set; } = string.Empty;
        public bool IsActive { get; set; }
    }
}
