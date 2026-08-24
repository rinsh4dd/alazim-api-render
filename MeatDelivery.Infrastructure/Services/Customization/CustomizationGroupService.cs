using System;
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
        private readonly SaveCustomizationGroupDtoValidator _saveValidator;

        public CustomizationGroupService(
            ICustomizationGroupRepository groupRepository,
            SaveCustomizationGroupDtoValidator saveValidator)
        {
            _groupRepository = groupRepository;
            _saveValidator = saveValidator;
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

                return ApiResponse<CustomizationGroupDto>.SuccessResponse(result, message);
            }
            catch (Exception ex)
            {
                return ApiResponse<CustomizationGroupDto>.FailureResponse(ex.Message);
            }
        }
    }
}
