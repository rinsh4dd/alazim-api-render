using System.Threading;
using System.Threading.Tasks;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MeatDelivery.Api.Extensions;
using MeatDelivery.Application.DTOs.Offer;
using MeatDelivery.Application.Interfaces.Offer;
using MeatDelivery.Shared.Constants;

namespace MeatDelivery.Api.Controllers
{
    [ApiController]
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}")]
    public class OffersController : BaseApiController
    {
        private readonly IOfferService _offerService;

        public OffersController(IOfferService offerService)
        {
            _offerService = offerService;
        }

        [HttpPost("admin/offers/save")]
        [Authorize(Roles = UserRoles.SuperAdminOrAdmin)]
        public async Task<IActionResult> SaveOffer(
            [FromBody] SaveOfferDto request,
            CancellationToken cancellationToken = default)
        {
            request.ActionedBy = HttpContext.GetUserId();
            var response = await _offerService.SaveOfferAsync(request, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpPost("admin/offers/get")]
        [Authorize(Roles = UserRoles.SuperAdminOrAdmin)]
        public async Task<IActionResult> GetOffers(
            [FromBody] GetOffersQueryDto query,
            CancellationToken cancellationToken = default)
        {
            var response = await _offerService.GetOffersAsync(query, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpGet("offers/active")]
        [AllowAnonymous]
        public async Task<IActionResult> GetActiveOffers(CancellationToken cancellationToken = default)
        {
            var response = await _offerService.GetActiveOffersAsync(cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }
    }
}
