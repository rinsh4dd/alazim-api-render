using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Customization;

namespace MeatDelivery.Application.Interfaces.Repositories.Customization
{
    public interface ICustomizationTemplateRepository
    {
        Task<CustomizationTemplateDto?> SaveCustomizationTemplateAsync(
            SaveCustomizationTemplateDto request,
            CancellationToken cancellationToken = default);
    }
}
