using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentValidation;
using MeatDelivery.Application.DTOs.Product;
using MeatDelivery.Application.Interfaces.Product;
using MeatDelivery.Application.Interfaces.Repositories.Product;
using MeatDelivery.Domain.Enums;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Infrastructure.Services.Catalog
{
    public class MeasurementUnitService : IMeasurementUnitService
    {
        private readonly IMeasurementUnitRepository _measurementUnitRepository;
        private readonly IValidator<SaveMeasurementUnitDto> _saveValidator;

        public MeasurementUnitService(
            IMeasurementUnitRepository measurementUnitRepository,
            IValidator<SaveMeasurementUnitDto> saveValidator)
        {
            _measurementUnitRepository = measurementUnitRepository;
            _saveValidator = saveValidator;
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

        public async Task<ApiResponse<MeasurementUnitDto>> SaveMeasurementUnitAsync(
            SaveMeasurementUnitDto request,
            CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(request);

            var validationResult = await _saveValidator.ValidateAsync(request, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<MeasurementUnitDto>.FailureResponse("Validation failed.", errors);
            }

            try
            {
                var result = await _measurementUnitRepository.SaveMeasurementUnitAsync(request, cancellationToken);
                if (result == null)
                {
                    return ApiResponse<MeasurementUnitDto>.FailureResponse("Failed to save measurement unit.");
                }

                string message = request.Mode switch
                {
                    Mode.ADD => "Measurement unit created successfully.",
                    Mode.EDIT => "Measurement unit updated successfully.",
                    _ => "Operation completed successfully."
                };

                return ApiResponse<MeasurementUnitDto>.SuccessResponse(result, message);
            }
            catch (Exception ex)
            {
                return ApiResponse<MeasurementUnitDto>.FailureResponse(ex.Message);
            }
        }
    }
}
