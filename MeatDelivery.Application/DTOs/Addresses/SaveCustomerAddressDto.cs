namespace MeatDelivery.Application.DTOs.Addresses
{
    public class SaveCustomerAddressDto
    {
        public string Mode { get; set; } = "ADD"; // "ADD", "EDIT", "DELETE"
        public long? AddressId { get; set; }
        public long? CustomerUserId { get; set; }
        public string? AddressType { get; set; }
        public string? ContactNumber { get; set; }
        public string? BuildingName { get; set; }
        public string? VillaOrFlatNo { get; set; }
        public string? Street { get; set; }
        public string? Area { get; set; }
        public string? City { get; set; }
        public string? Landmark { get; set; }
        public string? PostalCode { get; set; }
        public string? Emirate { get; set; }
        public decimal? Latitude { get; set; }
        public decimal? Longitude { get; set; }
        public bool? IsDefault { get; set; }
    }
}
