using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Product;
using MeatDelivery.Application.Interfaces.Product;
using MeatDelivery.Application.Interfaces.Repositories.Product;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Infrastructure.Services.Catalog
{
    public class MeasurementUnitService : IMeasurementUnitService
    {
        private readonly IMeasurementUnitRepository _measurementUnitRepository;

        public MeasurementUnitService(IMeasurementUnitRepository measurementUnitRepository)
        {
            _measurementUnitRepository = measurementUnitRepository;
        }

        public async Task<ApiResponse<List<MeasurementUnitDto>>> GetMeasurementUnitsAsync(
            bool? onlyActive = true,
            CancellationToken cancellationToken = default)
        {
            try
            {
                var units = await _measurementUnitRepository.GetMeasurementUnitsAsync(onlyActive, cancellationToken);
                return ApiResponse<List<MeasurementUnitDto>>.SuccessResponse(units, "Measurement units retrieved successfully.");
            }
            catch (Exception ex)
            {
                return ApiResponse<List<MeasurementUnitDto>>.FailureResponse(ex.Message);
            }
        }
    }
}
