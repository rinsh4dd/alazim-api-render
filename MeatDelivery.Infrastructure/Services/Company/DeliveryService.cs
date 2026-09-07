using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Company;
using MeatDelivery.Application.Interfaces.Company;
using MeatDelivery.Application.Interfaces.Repositories.Company;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Infrastructure.Services.Company
{
    public class DeliveryService : IDeliveryService
    {
        private readonly IDeliveryRepository _repository;

        public DeliveryService(IDeliveryRepository repository)
        {
            _repository = repository;
        }

        public async Task<ApiResponse<List<AvailableDeliveryDateDto>>> GetAvailableDeliveryDatesAsync(CancellationToken cancellationToken = default)
        {
            var dates = await _repository.GetAvailableDeliveryDatesAsync(cancellationToken);
            return ApiResponse<List<AvailableDeliveryDateDto>>.SuccessResponse(dates, "Available delivery dates retrieved successfully.");
        }
    }
}
