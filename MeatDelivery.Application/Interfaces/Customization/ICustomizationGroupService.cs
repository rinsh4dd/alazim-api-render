using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Customization;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Customization
{
    public interface ICustomizationGroupService
    {
        Task<ApiResponse<CustomizationGroupDto>> SaveCustomizationGroupAsync(
            SaveCustomizationGroupDto request,
            CancellationToken cancellationToken = default);
    }
}
