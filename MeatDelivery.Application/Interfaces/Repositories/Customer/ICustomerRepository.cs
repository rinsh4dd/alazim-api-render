using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Addresses;
using MeatDelivery.Application.DTOs.Customer;
using MeatDelivery.Domain.Entities.Addresses;

namespace MeatDelivery.Application.Interfaces.Repositories.Customer
{
    public interface ICustomerRepository
    {
        Task<List<CustomerAddress>> GetCustomerAddressAsync(
            GetCustomerAddressQueryDto query,
            long customerUserId,
            CancellationToken cancellationToken = default);

        Task<long> SaveCustomerAddressAsync(
            SaveCustomerAddressDto request,
            long customerUserId,
            CancellationToken cancellationToken = default);

        Task<bool> SetDefaultCustomerAddressAsync(
            long addressId,
            long customerUserId,
            CancellationToken cancellationToken = default);

        Task<CustomerProfileDto?> GetCustomerProfileAsync(
            long customerUserId,
            CancellationToken cancellationToken = default);

        Task<CustomerProfileDto> UpdateCustomerProfileAsync(
            UpdateCustomerProfileDto request,
            long customerUserId,
            CancellationToken cancellationToken = default);
    }
}
