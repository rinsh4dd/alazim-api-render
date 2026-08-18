using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Dapper;
using MeatDelivery.Application.DTOs.Product;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Product;

namespace MeatDelivery.Infrastructure.Repositories.Catalog
{
    public class MeasurementUnitRepository : IMeasurementUnitRepository
    {
        private readonly IDapperRepository _dapperRepository;

        public MeasurementUnitRepository(IDapperRepository dapperRepository)
        {
            _dapperRepository = dapperRepository;
        }

        public async Task<List<MeasurementUnitDto>> GetMeasurementUnitsAsync(
            bool? onlyActive = true,
            CancellationToken cancellationToken = default)
        {
            var units = await _dapperRepository.QueryAsync<MeasurementUnitDto>(
                "dbo.PR_GET_MEASUREMENT_UNITS",
                new { ONLY_ACTIVE = onlyActive }
            );

            return units.ToList();
        }

        public async Task<MeasurementUnitDto?> SaveMeasurementUnitAsync(
            SaveMeasurementUnitDto request,
            CancellationToken cancellationToken = default)
        {
            return await _dapperRepository.QueryFirstOrDefaultAsync<MeasurementUnitDto>(
                "dbo.PR_SAVE_MEASUREMENT_UNIT",
                new
                {
                    MODE = request.Mode.ToString(),
                    UNIT_ID = request.UnitId,
                    UNIT_DESCRIPTION = request.UnitDescription,
                    IS_ACTIVE = request.IsActive
                }
            );
        }
    }
}
