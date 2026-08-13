using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Addresses;
using MeatDelivery.Application.Interfaces.Customer;
using MeatDelivery.Application.Interfaces.Repositories.Customer;
using MeatDelivery.Domain.Entities.Addresses;
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

        public async Task<ApiResponse<List<CustomerAddressDto>>> GetCustomerAddressAsync(GetCustomerAddressQueryDto query,CancellationToken cancellationToken = default)
        {
            var addresses = await _customerRepository.GetCustomerAddressAsync(query, cancellationToken);
            var dtos = addresses.Select(MapToDto).ToList();

            string message = (query.AddressId.HasValue && query.AddressId.Value > 0)
                ? (dtos.Count > 0 ? "Address retrieved successfully." : "Address not found.")
                : "Addresses retrieved successfully.";

            return ApiResponse<List<CustomerAddressDto>>.SuccessResponse(dtos,message: message);
        }

        public async Task<ApiResponse<object>> SaveCustomerAddressAsync(
            SaveCustomerAddressDto request,
            CancellationToken cancellationToken = default)
        {
            var addressId = await _customerRepository.SaveCustomerAddressAsync(request, cancellationToken);

            string mode = request.Mode?.ToUpperInvariant() ?? "ADD";
            string message = mode switch
            {"ADD" => "Address added successfully.","EDIT" => "Address updated successfully.","DELETE" => "Address deleted successfully.",_ => "Address saved successfully."};

            return ApiResponse<object>.SuccessResponse(new { addressId = addressId > 0 ? addressId : request.AddressId },message: message);
        }

        private static CustomerAddressDto MapToDto(CustomerAddress a) => new()
        {
            AddressId = a.AddressId,
            CustomerUserId = a.CustomerUserId,
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
