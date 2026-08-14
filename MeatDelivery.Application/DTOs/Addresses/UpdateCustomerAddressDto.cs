using System;

namespace MeatDelivery.Application.DTOs.Addresses
{
    public class UpdateCustomerAddressDto
    {
        public string AddressLabel { get; set; } = string.Empty;
        public string Emirate { get; set; } = string.Empty;
        public string Area { get; set; } = string.Empty;
        public string? BuildingName { get; set; }
        public string? VillaApartmentNo { get; set; }
        public string? FloorNo { get; set; }
        public string? Landmark { get; set; }
        public string? PostalCode { get; set; }
        public string? DeliveryNotes { get; set; }
        public decimal? Latitude { get; set; }
        public decimal? Longitude { get; set; }
        public bool IsDefault { get; set; }
    }
}
