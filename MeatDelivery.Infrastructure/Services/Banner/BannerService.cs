using FluentValidation;
using Microsoft.Extensions.Caching.Memory;
using MeatDelivery.Application.DTOs.Banner;
using MeatDelivery.Application.Interfaces.Banner;
using MeatDelivery.Application.Interfaces.Repositories.Banner;
using MeatDelivery.Infrastructure.Helpers;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Infrastructure.Services.Banner;

public class BannerService : IBannerService
{
    private readonly IBannerRepository _bannerRepository;
    private readonly IValidator<SaveBannerDto> _validator;
    private readonly IMemoryCache _cache;

    private static CancellationTokenSource _bannerCacheTokenSource = new();

    public BannerService(
        IBannerRepository bannerRepository,
        IValidator<SaveBannerDto> validator,
        IMemoryCache cache)
    {
        _bannerRepository = bannerRepository;
        _validator = validator;
        _cache = cache;
    }

    public async Task<ApiResponse<BannerDto>> SaveBannerAsync(SaveBannerDto request, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var validationResult = await _validator.ValidateAsync(request, cancellationToken);
        if (!validationResult.IsValid)
        {
            var errors = validationResult.Errors.Select(e => e.ErrorMessage).ToList();
            return ApiResponse<BannerDto>.FailureResponse("Validation failed.", errors);
        }

        var result = await _bannerRepository.SaveBannerAsync(request, cancellationToken);

        if (result == null && !request.Mode.Equals("DELETE", StringComparison.OrdinalIgnoreCase))
        {
            return ApiResponse<BannerDto>.FailureResponse("Failed to process banner request.");
        }

        // Invalidate cached banners on modification
        CacheHelper.InvalidateToken(ref _bannerCacheTokenSource);

        string message = request.Mode.ToUpperInvariant() switch
        {
            "ADD" => "Banner created successfully.",
            "EDIT" => "Banner updated successfully.",
            "DELETE" => "Banner deleted successfully.",
            _ => "Operation completed successfully."
        };

        return ApiResponse<BannerDto>.SuccessResponse(result!, message);
    }

    public async Task<PagedResponse<List<BannerDto>>> GetBannersAsync(GetBannersQueryDto query, CancellationToken cancellationToken = default)
    {
        query ??= new GetBannersQueryDto();

        string cacheKey = $"banners:id_{query.BannerId}_active_{query.IsActive}_link_{query.LinkType}_s_{query.Search}_p_{query.PageNumber}_sz_{query.PageSize}";

        if (_cache.TryGetValue(cacheKey, out PagedResponse<List<BannerDto>>? cachedResponse) && cachedResponse != null)
        {
            return cachedResponse;
        }

        var (items, totalRecords) = await _bannerRepository.GetBannersAsync(query, cancellationToken);

        var response = new PagedResponse<List<BannerDto>>
        {
            Success = true,
            Message = "Banners retrieved successfully.",
            Data = items.ToList(),
            PageNumber = query.PageNumber,
            PageSize = query.PageSize,
            TotalRecords = totalRecords
        };

        var cacheOptions = CacheHelper.CreateOptions(_bannerCacheTokenSource, TimeSpan.FromMinutes(30));
        _cache.Set(cacheKey, response, cacheOptions);

        return response;
    }

    public async Task<ApiResponse<List<ActiveBannerDto>>> GetActiveBannersAsync(CancellationToken cancellationToken = default)
    {
        string cacheKey = "banners:active";

        if (_cache.TryGetValue(cacheKey, out ApiResponse<List<ActiveBannerDto>>? cachedResponse) && cachedResponse != null)
        {
            return cachedResponse;
        }

        var activeBanners = await _bannerRepository.GetActiveBannersAsync(cancellationToken);
        var response = ApiResponse<List<ActiveBannerDto>>.SuccessResponse(activeBanners.ToList(), "Active banners retrieved successfully.");

        var cacheOptions = CacheHelper.CreateOptions(_bannerCacheTokenSource, TimeSpan.FromMinutes(15));
        _cache.Set(cacheKey, response, cacheOptions);

        return response;
    }
}
