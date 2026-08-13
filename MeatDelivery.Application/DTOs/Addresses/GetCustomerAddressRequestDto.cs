namespace MeatDelivery.Application.DTOs.Addresses
{
    public class GetCustomerAddressRequestDto
    {
        public long? AddressId { get; set; }
        public string? AddressType { get; set; }
        public string? City { get; set; }
        public string? Emirate { get; set; }
        public string? Area { get; set; }
        public bool? IsDefault { get; set; }
        public string? Search { get; set; }
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 20;
    }
}
