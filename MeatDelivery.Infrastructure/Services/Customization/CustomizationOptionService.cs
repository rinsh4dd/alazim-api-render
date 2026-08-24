using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Customization;
using MeatDelivery.Application.Interfaces.Customization;
using MeatDelivery.Application.Interfaces.Repositories.Customization;
using MeatDelivery.Application.Validators.Customization;
using MeatDelivery.Domain.Enums;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Infrastructure.Services.Customization
{
    public class CustomizationOptionService : ICustomizationOptionService
    {
        private readonly ICustomizationOptionRepository _optionRepository;
        private readonly SaveCustomizationOptionDtoValidator _saveValidator = new();
        private readonly GetCustomizationOptionsQueryDtoValidator _getValidator = new();

        public CustomizationOptionService(ICustomizationOptionRepository optionRepository)
        {
            _optionRepository = optionRepository;
        }

        public async Task<ApiResponse<CustomizationOptionDto>> SaveCustomizationOptionAsync(
            SaveCustomizationOptionDto request,
            CancellationToken cancellationToken = default)
        {
            var validationResult = await _saveValidator.ValidateAsync(request, cancellationToken);
            if (!validationResult.IsValid)
            {
                return ApiResponse<CustomizationOptionDto>.FailureResponse(
                    "Validation failed.",
                    validationResult.Errors.Select(e => e.ErrorMessage).ToList());
            }

            try
            {
                var result = await _optionRepository.SaveCustomizationOptionAsync(request, cancellationToken);

                if (request.Mode == Mode.DELETE)
                {
                    return ApiResponse<CustomizationOptionDto>.SuccessResponse(
                        null!,
                        "Customization option deleted successfully.");
                }

                if (result == null)
                {
                    return ApiResponse<CustomizationOptionDto>.FailureResponse(
                        "Failed to save customization option.");
                }

                var successMessage = request.Mode == Mode.ADD
                    ? "Customization option created successfully."
                    : "Customization option updated successfully.";

                return ApiResponse<CustomizationOptionDto>.SuccessResponse(result, successMessage);
            }
            catch (Exception ex)
            {
                return ApiResponse<CustomizationOptionDto>.FailureResponse(
                    $"Error saving customization option: {ex.Message}");
            }
        }

        public async Task<PagedResponse<List<CustomizationOptionDto>>> GetCustomizationOptionsAsync(
            GetCustomizationOptionsQueryDto query,
            CancellationToken cancellationToken = default)
        {
            var validationResult = await _getValidator.ValidateAsync(query, cancellationToken);
            if (!validationResult.IsValid)
            {
                return new PagedResponse<List<CustomizationOptionDto>>
                {
                    Success = false,
                    Message = "Validation failed.",
                    Errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList()
                };
            }

            try
            {
                var (items, totalRecords) = await _optionRepository.GetCustomizationOptionsAsync(query, cancellationToken);

                return new PagedResponse<List<CustomizationOptionDto>>
                {
                    Success = true,
                    Message = "Customization options retrieved successfully.",
                    Data = items,
                    PageNumber = query.PageNumber,
                    PageSize = query.PageSize,
                    TotalRecords = totalRecords
                };
            }
            catch (Exception ex)
            {
                return new PagedResponse<List<CustomizationOptionDto>>
                {
                    Success = false,
                    Message = $"Error retrieving customization options: {ex.Message}",
                    Errors = new List<string> { ex.Message }
                };
            }
        }
    }
}
