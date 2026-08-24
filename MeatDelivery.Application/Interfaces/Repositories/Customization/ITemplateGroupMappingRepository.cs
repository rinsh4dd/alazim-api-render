using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Customization;

namespace MeatDelivery.Application.Interfaces.Repositories.Customization
{
    public interface ITemplateGroupMappingRepository
    {
        Task<List<TemplateGroupMappingDto>> SaveTemplateGroupMappingAsync(
            SaveTemplateGroupMappingDto dto,
            CancellationToken cancellationToken = default);

        Task<(List<TemplateGroupMappingDto> Items, int TotalRecords)> GetTemplateGroupMappingsAsync(
            GetTemplateGroupMappingsQueryDto query,
            CancellationToken cancellationToken = default);
    }
}
