using System;

namespace MeatDelivery.Application.DTOs.Addresses
{
    public class CustomerAddressDto
    {
        public long AddressId { get; set; }
        public long CustomerUserId { get; set; }
        public string AddressType { get; set; } = string.Empty; // HOME, OFFICE, OTHER
        public string ContactNumber { get; set; } = string.Empty;
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
        public bool IsDefault { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}
