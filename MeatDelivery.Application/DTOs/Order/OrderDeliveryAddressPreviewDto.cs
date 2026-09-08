namespace MeatDelivery.Application.DTOs.Order
{
    public class OrderDeliveryAddressPreviewDto
    {
        public long AddressId { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string AddressType { get; set; } = string.Empty;
        public string ContactNumber { get; set; } = string.Empty;
        public string? BuildingName { get; set; }
        public string VillaOrFlatNo { get; set; } = string.Empty;
        public string Street { get; set; } = string.Empty;
        public string Area { get; set; } = string.Empty;
        public string? Landmark { get; set; }
        public string City { get; set; } = string.Empty;
        public string Emirate { get; set; } = string.Empty;
        public string? PostalCode { get; set; }
        public decimal? Latitude { get; set; }
        public decimal? Longitude { get; set; }
        public bool IsDefault { get; set; }
    }
}
