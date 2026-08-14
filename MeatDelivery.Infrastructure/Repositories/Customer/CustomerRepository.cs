using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Addresses;
using MeatDelivery.Application.DTOs.Customer;
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
            long customerUserId,
            CancellationToken cancellationToken = default)
        {
            var result = await _dapperRepository.QueryAsync<CustomerAddress>(
                "PR_GET_CUSTOMER_ADDRESS",
                new
                {
                    ADDRESS_ID = query.AddressId,
                    CUSTOMER_USER_ID = customerUserId,
                    ADDRESS_TYPE = query.AddressType?.ToString(),
                    IS_DEFAULT = query.IsDefault
                }
            );

            return result.ToList();
        }

        public async Task<long> SaveCustomerAddressAsync(
            SaveCustomerAddressDto request,
            long customerUserId,
            CancellationToken cancellationToken = default)
        {
            var addressId = await _dapperRepository.ExecuteScalarAsync<long>(
                "PR_SAVE_CUSTOMER_ADDRESS",
                new
                {
                    MODE = request.Mode.ToString(),
                    ADDRESS_ID = request.AddressId,
                    CUSTOMER_USER_ID = customerUserId,
                    FIRST_NAME = request.FirstName,
                    LAST_NAME = request.LastName,
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
            long customerUserId,
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

        public async Task<CustomerProfileDto?> GetCustomerProfileAsync(
            long customerUserId,
            CancellationToken cancellationToken = default)
        {
            return await _dapperRepository.QueryFirstOrDefaultAsync<CustomerProfileDto>(
                "PR_CUSTOMER_GET_PROFILE",
                new
                {
                    USER_ID = customerUserId
                }
            );
        }

        public async Task<CustomerProfileDto> UpdateCustomerProfileAsync(
            UpdateCustomerProfileDto request,
            long customerUserId,
            CancellationToken cancellationToken = default)
        {
            var result = await _dapperRepository.QueryFirstOrDefaultAsync<CustomerProfileDto>(
                "PR_CUSTOMER_UPDATE_PROFILE",
                new
                {
                    USER_ID = customerUserId,
                    FIRST_NAME = request.FirstName,
                    LAST_NAME = request.LastName,
                    EMAIL = request.Email,
                    DOB = request.Dob,
                    GENDER = request.Gender?.ToString(),
                    PROFILE_IMAGE_URL = request.ProfileImageUrl,
                    LANGUAGE_CODE = request.LanguageCode
                }
            );

            return result ?? throw new InvalidOperationException("Failed to update customer profile.");
        }
    }
}
