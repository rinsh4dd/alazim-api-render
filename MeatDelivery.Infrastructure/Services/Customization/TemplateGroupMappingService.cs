using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Customization;
using MeatDelivery.Application.Interfaces.Customization;
using MeatDelivery.Application.Interfaces.Repositories.Customization;
using MeatDelivery.Application.Validators.Customization;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Infrastructure.Services.Customization
{
    public class TemplateGroupMappingService : ITemplateGroupMappingService
    {
        private readonly ITemplateGroupMappingRepository _mappingRepository;
        private readonly SaveTemplateGroupMappingDtoValidator _saveValidator = new();
        private readonly GetTemplateGroupMappingsQueryDtoValidator _getValidator = new();

        public TemplateGroupMappingService(ITemplateGroupMappingRepository mappingRepository)
        {
            _mappingRepository = mappingRepository;
        }

        public async Task<ApiResponse<List<TemplateGroupMappingDto>>> SaveTemplateGroupMappingAsync(
            SaveTemplateGroupMappingDto request,
            CancellationToken cancellationToken = default)
        {
            var validationResult = await _saveValidator.ValidateAsync(request, cancellationToken);
            if (!validationResult.IsValid)
            {
                return ApiResponse<List<TemplateGroupMappingDto>>.FailureResponse(
                    "Validation failed.",
                    validationResult.Errors.Select(e => e.ErrorMessage).ToList());
            }

            try
            {
                var result = await _mappingRepository.SaveTemplateGroupMappingAsync(request, cancellationToken);

                return ApiResponse<List<TemplateGroupMappingDto>>.SuccessResponse(
                    result,
                    "Template group mappings updated successfully.");
            }
            catch (Exception ex)
            {
                return ApiResponse<List<TemplateGroupMappingDto>>.FailureResponse(
                    $"Error saving template group mapping: {ex.Message}");
            }
        }

        public async Task<PagedResponse<List<TemplateGroupMappingDto>>> GetTemplateGroupMappingsAsync(
            GetTemplateGroupMappingsQueryDto query,
            CancellationToken cancellationToken = default)
        {
            var validationResult = await _getValidator.ValidateAsync(query, cancellationToken);
            if (!validationResult.IsValid)
            {
                return new PagedResponse<List<TemplateGroupMappingDto>>
                {
                    Success = false,
                    Message = "Validation failed.",
                    Errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList()
                };
            }

            try
            {
                var (items, totalRecords) = await _mappingRepository.GetTemplateGroupMappingsAsync(query, cancellationToken);

                return new PagedResponse<List<TemplateGroupMappingDto>>
                {
                    Success = true,
                    Message = "Template group mappings retrieved successfully.",
                    Data = items,
                    PageNumber = query.PageNumber,
                    PageSize = query.PageSize,
                    TotalRecords = totalRecords
                };
            }
            catch (Exception ex)
            {
                return new PagedResponse<List<TemplateGroupMappingDto>>
                {
                    Success = false,
                    Message = $"Error retrieving template group mappings: {ex.Message}",
                    Errors = new List<string> { ex.Message }
                };
            }
        }
    }
}
