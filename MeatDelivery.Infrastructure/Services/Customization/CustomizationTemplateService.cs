using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentValidation;
using MeatDelivery.Application.DTOs.Customization;
using MeatDelivery.Application.Interfaces.Customization;
using MeatDelivery.Application.Interfaces.Repositories.Customization;
using MeatDelivery.Domain.Enums;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Infrastructure.Services.Customization
{
    public class CustomizationTemplateService : ICustomizationTemplateService
    {
        private readonly ICustomizationTemplateRepository _customizationTemplateRepository;
        private readonly IValidator<SaveCustomizationTemplateDto> _saveValidator;

        public CustomizationTemplateService(
            ICustomizationTemplateRepository customizationTemplateRepository,
            IValidator<SaveCustomizationTemplateDto> saveValidator)
        {
            _customizationTemplateRepository = customizationTemplateRepository;
            _saveValidator = saveValidator;
        }

        public async Task<ApiResponse<CustomizationTemplateDto>> SaveCustomizationTemplateAsync(
            SaveCustomizationTemplateDto request,
            CancellationToken cancellationToken = default)
        {
            ArgumentNullException.ThrowIfNull(request);

            var validationResult = await _saveValidator.ValidateAsync(request, cancellationToken);
            if (!validationResult.IsValid)
            {
                var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
                return ApiResponse<CustomizationTemplateDto>.FailureResponse("Validation failed.", errors);
            }

            try
            {
                var result = await _customizationTemplateRepository.SaveCustomizationTemplateAsync(request, cancellationToken);

                if (result == null && request.Mode != Mode.DELETE)
                {
                    return ApiResponse<CustomizationTemplateDto>.FailureResponse("Failed to process customization template request.");
                }

                string message = request.Mode switch
                {
                    Mode.ADD => "Customization template created successfully.",
                    Mode.EDIT => "Customization template updated successfully.",
                    Mode.DELETE => "Customization template deleted successfully.",
                    _ => "Operation completed successfully."
                };

                return ApiResponse<CustomizationTemplateDto>.SuccessResponse(result!, message);
            }
            catch (Exception ex)
            {
                return ApiResponse<CustomizationTemplateDto>.FailureResponse(ex.Message);
            }
        }
    }
}
