namespace MeatDelivery.Application.DTOs.Addresses
{
    public class GetCustomerAddressQueryDto
    {
        public long? AddressId { get; set; }
        public long? CustomerUserId { get; set; }
        public string? AddressType { get; set; } // HOME, OFFICE, OTHER
        public bool? IsDefault { get; set; }
    }
}
