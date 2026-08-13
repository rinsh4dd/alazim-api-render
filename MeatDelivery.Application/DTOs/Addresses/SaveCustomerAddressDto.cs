using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Addresses
{
    public class SaveCustomerAddressDto
    {
        public AddressMode Mode { get; set; } = AddressMode.ADD;
        public long? AddressId { get; set; }
        public long? CustomerUserId { get; set; }
        public AddressType? AddressType { get; set; }
        public string? ContactNumber { get; set; }
        public string? BuildingName { get; set; }
        public string VillaOrFlatNo { get; set; } = string.Empty;
        public string Street { get; set; } = string.Empty;
        public string Area { get; set; } = string.Empty;
        public string City { get; set; } = string.Empty;
        public string? Landmark { get; set; }
        public string? PostalCode { get; set; }
        public string Emirate { get; set; } = string.Empty;
        public decimal? Latitude { get; set; }
        public decimal? Longitude { get; set; }
        public bool? IsDefault { get; set; }
    }
}
