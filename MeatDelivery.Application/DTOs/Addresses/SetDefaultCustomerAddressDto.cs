namespace MeatDelivery.Application.DTOs.Addresses
{
    public class SetDefaultCustomerAddressDto
    {
        public long AddressId { get; set; }
        public long? CustomerUserId { get; set; }
    }
}
