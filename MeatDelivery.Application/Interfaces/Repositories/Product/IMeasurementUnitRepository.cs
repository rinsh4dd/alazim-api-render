using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Product;

namespace MeatDelivery.Application.Interfaces.Repositories.Product
{
    public interface IMeasurementUnitRepository
    {
        Task<List<MeasurementUnitDto>> GetMeasurementUnitsAsync(bool? onlyActive = true, CancellationToken cancellationToken = default);
        Task<MeasurementUnitDto?> SaveMeasurementUnitAsync(SaveMeasurementUnitDto request, CancellationToken cancellationToken = default);
    }
}
