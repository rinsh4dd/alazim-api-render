using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Customization;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Customization
{
    public interface ITemplateGroupMappingService
    {
        Task<ApiResponse<List<TemplateGroupMappingDto>>> SaveTemplateGroupMappingAsync(
            SaveTemplateGroupMappingDto request,
            CancellationToken cancellationToken = default);

        Task<PagedResponse<List<TemplateGroupMappingDto>>> GetTemplateGroupMappingsAsync(
            GetTemplateGroupMappingsQueryDto query,
            CancellationToken cancellationToken = default);
    }
}
