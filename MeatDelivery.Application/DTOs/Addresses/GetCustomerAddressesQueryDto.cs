namespace MeatDelivery.Application.DTOs.Addresses
{
    public class GetCustomerAddressesQueryDto
    {
        public string? Search { get; set; }
        public string? Emirate { get; set; }
        public string? Area { get; set; }
        public bool? IsDefault { get; set; }
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 20;
    }
}
