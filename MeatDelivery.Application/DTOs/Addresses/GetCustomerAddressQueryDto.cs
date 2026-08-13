using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Application.DTOs.Addresses
{
    public class GetCustomerAddressQueryDto
    {
        public long? AddressId { get; set; }
        public long? CustomerUserId { get; set; }
        public AddressType? AddressType { get; set; }
        public bool? IsDefault { get; set; }
    }
}
