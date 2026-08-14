using System;

namespace MeatDelivery.Application.DTOs.Addresses
{
    public class CreateCustomerAddressDto
    {
        public string AddressLabel { get; set; } = string.Empty; // e.g. "Home", "Office", "Villa"
        public string Emirate { get; set; } = string.Empty;      // e.g. "Dubai", "Abu Dhabi", "Sharjah"
        public string Area { get; set; } = string.Empty;         // e.g. "Downtown", "Marina", "Deira"
        public string? BuildingName { get; set; }
        public string? VillaApartmentNo { get; set; }
        public string? FloorNo { get; set; }
        public string? Landmark { get; set; }
        public string? PostalCode { get; set; }
        public string? DeliveryNotes { get; set; }
        public decimal? Latitude { get; set; }
        public decimal? Longitude { get; set; }
        public bool IsDefault { get; set; } = false;
    }
}
