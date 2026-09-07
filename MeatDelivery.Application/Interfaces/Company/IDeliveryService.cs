using System;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Company
{
    public interface IDeliveryService
    {
        Task<ApiResponse<object>> GetAvailableSlotsAsync(DateTime? targetDate = null, CancellationToken cancellationToken = default);
    }
}
