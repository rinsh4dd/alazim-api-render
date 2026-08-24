using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Customization;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Customization
{
    public interface ICustomizationTemplateService
    {
        Task<ApiResponse<CustomizationTemplateDto>> SaveCustomizationTemplateAsync(
            SaveCustomizationTemplateDto request,
            CancellationToken cancellationToken = default);
    }
}
