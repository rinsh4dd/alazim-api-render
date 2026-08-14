using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Addresses;
using MeatDelivery.Application.DTOs.Customer;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Customer
{
    public interface ICustomerService
    {
        Task<ApiResponse<List<CustomerAddressDto>>> GetCustomerAddressAsync(
            GetCustomerAddressQueryDto query,
            long customerUserId,
            CancellationToken cancellationToken = default);

        Task<ApiResponse<object>> SaveCustomerAddressAsync(
            SaveCustomerAddressDto request,
            long customerUserId,
            CancellationToken cancellationToken = default);

        Task<ApiResponse<object>> SetDefaultCustomerAddressAsync(
            long addressId,
            long customerUserId,
            CancellationToken cancellationToken = default);

        Task<ApiResponse<CustomerProfileDto>> GetCustomerProfileAsync(
            long customerUserId,
            CancellationToken cancellationToken = default);

        Task<ApiResponse<CustomerProfileDto>> UpdateCustomerProfileAsync(
            UpdateCustomerProfileDto request,
            long customerUserId,
            CancellationToken cancellationToken = default);
    }
}
