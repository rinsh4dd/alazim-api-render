using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace MeatDelivery.Application.DTOs.Addresses
{
    public class GetCustomerAddressResponseDto
    {
        // Populated when querying by specific addressId:
        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
        public CustomerAddressDto? Address { get; set; }

        // Populated when querying list of addresses:
        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
        public List<CustomerAddressDto>? Addresses { get; set; }

        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
        public int? TotalCount { get; set; }

        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
        public int? Page { get; set; }

        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
        public int? PageSize { get; set; }

        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
        public int? TotalPages => (PageSize.HasValue && PageSize.Value > 0 && TotalCount.HasValue)
            ? (int)Math.Ceiling((double)TotalCount.Value / PageSize.Value)
            : null;
    }
}
