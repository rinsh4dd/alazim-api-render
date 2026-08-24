using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Customization;

namespace MeatDelivery.Application.Interfaces.Repositories.Customization
{
    public interface ICustomizationOptionRepository
    {
        Task<CustomizationOptionDto?> SaveCustomizationOptionAsync(
            SaveCustomizationOptionDto dto,
            CancellationToken cancellationToken = default);

        Task<(List<CustomizationOptionDto> Items, int TotalRecords)> GetCustomizationOptionsAsync(
            GetCustomizationOptionsQueryDto query,
            CancellationToken cancellationToken = default);
    }
}
