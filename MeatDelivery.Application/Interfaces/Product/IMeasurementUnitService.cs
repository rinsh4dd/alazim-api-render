using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Product;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Product
{
    public interface IMeasurementUnitService
    {
        Task<ApiResponse<List<MeasurementUnitDto>>> GetMeasurementUnitsAsync(bool? onlyActive = true, CancellationToken cancellationToken = default);
    }
}
