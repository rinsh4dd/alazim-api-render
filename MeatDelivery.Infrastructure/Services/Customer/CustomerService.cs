using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Addresses;
using MeatDelivery.Application.DTOs.Customer;
using MeatDelivery.Application.Interfaces.Customer;
using MeatDelivery.Application.Interfaces.Repositories.Customer;
using MeatDelivery.Domain.Entities.Addresses;
using MeatDelivery.Domain.Enums;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Infrastructure.Services.Customer
{
    public class CustomerService : ICustomerService
    {
        private readonly ICustomerRepository _customerRepository;

        public CustomerService(ICustomerRepository customerRepository)
        {
            _customerRepository = customerRepository;
        }

        public async Task<ApiResponse<List<CustomerAddressDto>>> GetCustomerAddressAsync(
            GetCustomerAddressQueryDto query,
            long customerUserId,
            CancellationToken cancellationToken = default)
        {
            var addresses = await _customerRepository.GetCustomerAddressAsync(query, customerUserId, cancellationToken);
            var dtos = addresses.Select(MapToDto).ToList();

            string message = (query.AddressId.HasValue && query.AddressId.Value > 0)
                ? (dtos.Count > 0 ? "Address retrieved successfully." : "Address not found.")
                : "Addresses retrieved successfully.";

            return ApiResponse<List<CustomerAddressDto>>.SuccessResponse(
                dtos,
                message: message);
        }

        public async Task<ApiResponse<object>> SaveCustomerAddressAsync(
            SaveCustomerAddressDto request,
            long customerUserId,
            CancellationToken cancellationToken = default)
        {
            var addressId = await _customerRepository.SaveCustomerAddressAsync(request, customerUserId, cancellationToken);

            string message = request.Mode switch
            {
                AddressMode.ADD => "Address added successfully.",
                AddressMode.EDIT => "Address updated successfully.",
                AddressMode.DELETE => "Address deleted successfully.",
                _ => "Address saved successfully."
            };

            return ApiResponse<object>.SuccessResponse(
                new { addressId = addressId > 0 ? addressId : request.AddressId },
                message: message);
        }

        public async Task<ApiResponse<object>> SetDefaultCustomerAddressAsync(
            long addressId,
            long customerUserId,
            CancellationToken cancellationToken = default)
        {
            await _customerRepository.SetDefaultCustomerAddressAsync(
                addressId,
                customerUserId,
                cancellationToken);

            return ApiResponse<object>.SuccessResponse(
                new { addressId = addressId },
                message: "Default delivery address updated successfully.");
        }

        public async Task<ApiResponse<CustomerProfileDto>> GetCustomerProfileAsync(
            long customerUserId,
            CancellationToken cancellationToken = default)
        {
            var profile = await _customerRepository.GetCustomerProfileAsync(customerUserId, cancellationToken);
            if (profile == null)
            {
                return ApiResponse<CustomerProfileDto>.FailureResponse(
                    message: "Customer profile not found.",
                    status: 404);
            }

            return ApiResponse<CustomerProfileDto>.SuccessResponse(
                profile,
                message: "Customer profile retrieved successfully.");
        }

        public async Task<ApiResponse<CustomerProfileDto>> UpdateCustomerProfileAsync(
            UpdateCustomerProfileDto request,
            long customerUserId,
            CancellationToken cancellationToken = default)
        {
            var profile = await _customerRepository.UpdateCustomerProfileAsync(request, customerUserId, cancellationToken);

            

            return ApiResponse<CustomerProfileDto>.SuccessResponse(
                profile,
                message: "Profile updated successfully");
        }

        private static CustomerAddressDto MapToDto(CustomerAddress a) => new()
        {
            AddressId = a.AddressId,
            CustomerUserId = a.CustomerUserId,
            FirstName = a.FirstName,
            LastName = a.LastName,
            AddressType = a.AddressType,
            ContactNumber = a.ContactNumber,
            BuildingName = a.BuildingName,
            VillaOrFlatNo = a.VillaOrFlatNo,
            Street = a.Street,
            Area = a.Area,
            City = a.City,
            Landmark = a.Landmark,
            PostalCode = a.PostalCode,
            Emirate = a.Emirate,
            Latitude = a.Latitude,
            Longitude = a.Longitude,
            IsDefault = a.IsDefault,
            IsActive = a.IsActive,
            CreatedAt = a.CreatedAt,
            UpdatedAt = a.UpdatedAt
        };
    }
}
