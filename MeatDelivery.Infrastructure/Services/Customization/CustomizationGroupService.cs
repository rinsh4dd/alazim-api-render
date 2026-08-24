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
    public class CustomizationGroupService : ICustomizationGroupService
    {
        private readonly ICustomizationGroupRepository _groupRepository;
        private readonly SaveCustomizationGroupDtoValidator _saveValidator = new();
        private readonly GetCustomizationGroupsQueryDtoValidator _getValidator = new();

        public CustomizationGroupService(ICustomizationGroupRepository groupRepository)
        {
            _groupRepository = groupRepository;
        }

        public async Task<ApiResponse<CustomizationGroupDto>> SaveCustomizationGroupAsync(
            SaveCustomizationGroupDto request,
            CancellationToken cancellationToken = default)
        {
            var validationResult = await _saveValidator.ValidateAsync(request, cancellationToken);
            if (!validationResult.IsValid)
            {
                return ApiResponse<CustomizationGroupDto>.FailureResponse(
                    "Validation failed.",
                    validationResult.Errors.Select(e => e.ErrorMessage).ToList());
            }

            try
            {
                var result = await _groupRepository.SaveCustomizationGroupAsync(request, cancellationToken);

                string message = request.Mode switch
                {
                    Mode.ADD => "Customization group created successfully.",
                    Mode.EDIT => "Customization group updated successfully.",
                    Mode.DELETE => "Customization group deleted successfully.",
                    _ => "Operation completed successfully."
                };

                return ApiResponse<CustomizationGroupDto>.SuccessResponse(result!, message);
            }
            catch (Exception ex)
            {
                return ApiResponse<CustomizationGroupDto>.FailureResponse(ex.Message);
            }
        }

        public async Task<PagedResponse<List<CustomizationGroupDto>>> GetCustomizationGroupsAsync(
            GetCustomizationGroupsQueryDto query,
            CancellationToken cancellationToken = default)
        {
            var validationResult = await _getValidator.ValidateAsync(query, cancellationToken);
            if (!validationResult.IsValid)
            {
                return new PagedResponse<List<CustomizationGroupDto>>
                {
                    Success = false,
                    Message = "Validation failed.",
                    Errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList()
                };
            }

            try
            {
                var (items, totalRecords) = await _groupRepository.GetCustomizationGroupsAsync(query, cancellationToken);

                return new PagedResponse<List<CustomizationGroupDto>>
                {
                    Success = true,
                    Message = "Customization groups retrieved successfully.",
                    Data = items,
                    PageNumber = query.PageNumber,
                    PageSize = query.PageSize,
                    TotalRecords = totalRecords
                };
            }
            catch (Exception ex)
            {
                return new PagedResponse<List<CustomizationGroupDto>>
                {
                    Success = false,
                    Message = ex.Message
                };
            }
        }
    }
}
