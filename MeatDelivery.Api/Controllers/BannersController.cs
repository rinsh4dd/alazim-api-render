using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MeatDelivery.Api.Extensions;
using MeatDelivery.Application.DTOs.Banner;
using MeatDelivery.Application.Interfaces.Banner;
using MeatDelivery.Shared.Constants;

namespace MeatDelivery.Api.Controllers;

[ApiController]
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/banners")]
public class BannersController : BaseApiController
{
    private readonly IBannerService _bannerService;

    public BannersController(IBannerService bannerService)
    {
        _bannerService = bannerService;
    }

    [HttpPost("admin/save")]
    [Authorize(Roles = UserRoles.SuperAdminOrAdmin)]
    public async Task<IActionResult> SaveBanner([FromBody] SaveBannerDto request, CancellationToken cancellationToken = default)
    {
        request.ActionedBy = HttpContext.GetUserId();
        var response = await _bannerService.SaveBannerAsync(request, cancellationToken);
        response.TraceId = HttpContext.TraceIdentifier;
        return Ok(response);
    }

    [HttpGet("admin/get")]
    [Authorize(Roles = UserRoles.SuperAdminOrAdmin)]
    public async Task<IActionResult> GetBanners([FromQuery] GetBannersQueryDto query, CancellationToken cancellationToken = default)
    {
        var response = await _bannerService.GetBannersAsync(query, cancellationToken);
        response.TraceId = HttpContext.TraceIdentifier;
        return Ok(response);
    }

    [HttpGet("active")]
    [AllowAnonymous]
    public async Task<IActionResult> GetActiveBanners(CancellationToken cancellationToken = default)
    {
        var response = await _bannerService.GetActiveBannersAsync(cancellationToken);
        response.TraceId = HttpContext.TraceIdentifier;
        return Ok(response);
    }
}
