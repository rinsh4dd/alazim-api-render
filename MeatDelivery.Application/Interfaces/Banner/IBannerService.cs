using MeatDelivery.Application.DTOs.Banner;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Banner;

public interface IBannerService
{
    Task<ApiResponse<BannerDto>> SaveBannerAsync(SaveBannerDto request, CancellationToken cancellationToken = default);
    Task<PagedResponse<List<BannerDto>>> GetBannersAsync(GetBannersQueryDto query, CancellationToken cancellationToken = default);
    Task<ApiResponse<List<ActiveBannerDto>>> GetActiveBannersAsync(CancellationToken cancellationToken = default);
}
