using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Addresses;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Customer;
using MeatDelivery.Domain.Entities.Addresses;

namespace MeatDelivery.Infrastructure.Repositories.Customer
{
    public class CustomerRepository : ICustomerRepository
    {
        private readonly IDapperRepository _dapperRepository;

        public CustomerRepository(IDapperRepository dapperRepository)
        {
            _dapperRepository = dapperRepository;
        }

        public async Task<List<CustomerAddress>> GetCustomerAddressAsync(
            GetCustomerAddressQueryDto query,
            CancellationToken cancellationToken = default)
        {
            var result = await _dapperRepository.QueryAsync<CustomerAddress>(
                "PR_GET_CUSTOMER_ADDRESS",
                new
                {
                    ADDRESS_ID = query.AddressId,
                    CUSTOMER_USER_ID = query.CustomerUserId,
                    ADDRESS_TYPE = query.AddressType?.ToString(),
                    IS_DEFAULT = query.IsDefault
                }
            );

            return result.ToList();
        }

        public async Task<long> SaveCustomerAddressAsync(
            SaveCustomerAddressDto request,
            CancellationToken cancellationToken = default)
        {
            var addressId = await _dapperRepository.ExecuteScalarAsync<long>(
                "PR_SAVE_CUSTOMER_ADDRESS",
                new
                {
                    MODE = request.Mode.ToString(),
                    ADDRESS_ID = request.AddressId,
                    CUSTOMER_USER_ID = request.CustomerUserId,
                    ADDRESS_TYPE = request.AddressType?.ToString(),
                    CONTACT_NUMBER = request.ContactNumber,
                    BUILDING_NAME = request.BuildingName,
                    VILLA_OR_FLAT_NO = request.VillaOrFlatNo,
                    STREET = request.Street,
                    AREA = request.Area,
                    CITY = request.City,
                    LANDMARK = request.Landmark,
                    POSTAL_CODE = request.PostalCode,
                    EMIRATE = request.Emirate,
                    LATITUDE = request.Latitude,
                    LONGITUDE = request.Longitude,
                    IS_DEFAULT = request.IsDefault
                }
            );

            return addressId;
        }

        public async Task<bool> SetDefaultCustomerAddressAsync(
            long addressId,
            long? customerUserId = null,
            CancellationToken cancellationToken = default)
        {
            await _dapperRepository.ExecuteAsync(
                "PR_SET_DEFAULT_CUSTOMER_ADDRESS",
                new
                {
                    ADDRESS_ID = addressId,
                    CUSTOMER_USER_ID = customerUserId
                }
            );
            return true;
        }
    }
}
