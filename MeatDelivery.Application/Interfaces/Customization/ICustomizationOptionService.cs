using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Customization;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Customization
{
    public interface ICustomizationOptionService
    {
        Task<ApiResponse<CustomizationOptionDto>> SaveCustomizationOptionAsync(
            SaveCustomizationOptionDto request,
            CancellationToken cancellationToken = default);

        Task<PagedResponse<List<CustomizationOptionDto>>> GetCustomizationOptionsAsync(
            GetCustomizationOptionsQueryDto query,
            CancellationToken cancellationToken = default);
    }
}
