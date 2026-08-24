using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Customization;

namespace MeatDelivery.Application.Interfaces.Repositories.Customization
{
    public interface ICustomizationGroupRepository
    {
        Task<CustomizationGroupDto?> SaveCustomizationGroupAsync(
            SaveCustomizationGroupDto request,
            CancellationToken cancellationToken = default);
    }
}
