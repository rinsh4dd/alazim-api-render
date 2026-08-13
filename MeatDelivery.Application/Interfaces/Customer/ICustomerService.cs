using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Addresses;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Customer
{
    public interface ICustomerService
    {
        Task<ApiResponse<List<CustomerAddressDto>>> GetCustomerAddressAsync(
            GetCustomerAddressQueryDto query,
            CancellationToken cancellationToken = default);

        Task<ApiResponse<object>> SaveCustomerAddressAsync(
            SaveCustomerAddressDto request,
            CancellationToken cancellationToken = default);
    }
}
