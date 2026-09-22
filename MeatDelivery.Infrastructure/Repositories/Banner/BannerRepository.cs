using MeatDelivery.Application.DTOs.Banner;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Banner;

namespace MeatDelivery.Infrastructure.Repositories.Banner;

public class BannerRepository : IBannerRepository
{
    private readonly IDapperRepository _dapperRepository;

    public BannerRepository(IDapperRepository dapperRepository)
    {
        _dapperRepository = dapperRepository;
    }

    public async Task<BannerDto?> SaveBannerAsync(SaveBannerDto request, CancellationToken cancellationToken = default)
    {
        return await _dapperRepository.QueryFirstOrDefaultAsync<BannerDto>(
            "dbo.PR_SAVE_BANNER",
            new
            {
                MODE = request.Mode,
                BANNER_ID = request.BannerId,
                TITLE_EN = request.TitleEn,
                TITLE_AR = request.TitleAr,
                ALT_TEXT_EN = request.AltTextEn,
                ALT_TEXT_AR = request.AltTextAr,
                IMAGE_URL = request.ImageUrl,
                LINK_TYPE = request.LinkType,
                PRODUCT_ID = request.ProductId,
                CATEGORY_ID = request.CategoryId,
                OFFER_ID = request.OfferId,
                EXTERNAL_URL = request.ExternalUrl,
                START_AT = request.StartAt,
                END_AT = request.EndAt,
                IS_ACTIVE = request.IsActive,
                ACTIONED_BY = request.ActionedBy
            }
        );
    }

    public async Task<(IEnumerable<BannerDto> Items, int TotalRecords)> GetBannersAsync(GetBannersQueryDto query, CancellationToken cancellationToken = default)
    {
        return await _dapperRepository.QueryMultipleAsync(
            "dbo.PR_GET_BANNERS",
            async grid =>
            {
                var totalRecords = (await grid.ReadAsync<int>()).FirstOrDefault();
                var items = await grid.ReadAsync<BannerDto>();
                return (items, totalRecords);
            },
            new
            {
                BANNER_ID = query.BannerId,
                IS_ACTIVE = query.IsActive,
                LINK_TYPE = query.LinkType,
                SEARCH = query.Search,
                PAGE_NUMBER = query.PageNumber,
                PAGE_SIZE = query.PageSize
            }
        );
    }

    public async Task<IEnumerable<ActiveBannerDto>> GetActiveBannersAsync(CancellationToken cancellationToken = default)
    {
        return await _dapperRepository.QueryAsync<ActiveBannerDto>("dbo.PR_GET_ACTIVE_BANNERS");
    }
}
