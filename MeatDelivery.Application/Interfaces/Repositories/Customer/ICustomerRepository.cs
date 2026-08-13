using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Addresses;
using MeatDelivery.Domain.Entities.Addresses;

namespace MeatDelivery.Application.Interfaces.Repositories.Customer
{
    public interface ICustomerRepository
    {
        Task<List<CustomerAddress>> GetCustomerAddressAsync(
            GetCustomerAddressQueryDto query,
            CancellationToken cancellationToken = default);

        Task<long> SaveCustomerAddressAsync(
            SaveCustomerAddressDto request,
            CancellationToken cancellationToken = default);
    }
}
