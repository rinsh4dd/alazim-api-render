using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Company;

namespace MeatDelivery.Application.Interfaces.Repositories.Company
{
    public interface IDeliveryRepository
    {
        Task<List<AvailableDeliveryDateDto>> GetAvailableDeliveryDatesAsync(CancellationToken cancellationToken = default);
        Task<List<DeliverySlotDto>> GetAvailableSlotsAsync(DateTime? targetDate = null, CancellationToken cancellationToken = default);
    }
}
