using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Company;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Company
{
    public interface IDeliveryService
    {
        Task<ApiResponse<List<AvailableDeliveryDateDto>>> GetAvailableDeliveryDatesAsync(CancellationToken cancellationToken = default);
    }
}
