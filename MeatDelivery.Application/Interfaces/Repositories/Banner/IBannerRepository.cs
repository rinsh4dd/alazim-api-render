using MeatDelivery.Application.DTOs.Banner;

namespace MeatDelivery.Application.Interfaces.Repositories.Banner;

public interface IBannerRepository
{
    Task<BannerDto?> SaveBannerAsync(SaveBannerDto request, CancellationToken cancellationToken = default);
    Task<(IEnumerable<BannerDto> Items, int TotalRecords)> GetBannersAsync(GetBannersQueryDto query, CancellationToken cancellationToken = default);
    Task<IEnumerable<ActiveBannerDto>> GetActiveBannersAsync(CancellationToken cancellationToken = default);
}
