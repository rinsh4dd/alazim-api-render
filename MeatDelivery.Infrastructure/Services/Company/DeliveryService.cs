using System;
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

        public async Task<ApiResponse<object>> GetAvailableSlotsAsync(DateTime? targetDate = null, CancellationToken cancellationToken = default)
        {
            if (!targetDate.HasValue)
            {
                var dates = await _repository.GetAvailableDeliveryDatesAsync(cancellationToken);
                return ApiResponse<object>.SuccessResponse(dates, "Available delivery dates retrieved successfully.");
            }

            var date = targetDate.Value.Date;
            var slots = await _repository.GetAvailableSlotsAsync(date, cancellationToken);

            return ApiResponse<object>.SuccessResponse(slots, "Available delivery slots retrieved successfully.");
        }
    }
}
