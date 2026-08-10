namespace MeatDelivery.Application.DTOs.Test
{
    /// <summary>
    /// A sample DTO used to demonstrate data transfer between the API and Application layers.
    /// DTOs (Data Transfer Objects) should only contain data properties, with no business logic.
    /// </summary>
    public class SampleUpdateDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
    }
}
