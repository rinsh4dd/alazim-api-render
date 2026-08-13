using System;
using System.Collections.Generic;

namespace MeatDelivery.Application.DTOs.Addresses
{
    public class PaginatedAddressResultDto
    {
        public List<CustomerAddressDto> Items { get; set; } = new();
        public int TotalCount { get; set; }
        public int Page { get; set; }
        public int PageSize { get; set; }
        public int TotalPages => PageSize > 0 ? (int)Math.Ceiling((double)TotalCount / PageSize) : 0;
        public bool HasPreviousPage => Page > 1;
        public bool HasNextPage => Page < TotalPages;
    }
}
