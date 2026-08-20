using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using MeatDelivery.Api.Extensions;
using MeatDelivery.Application.DTOs.Wishlist;
using MeatDelivery.Application.Interfaces.Wishlist;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Api.Controllers
{
    [ApiController]
    [Route("api/v1/wishlist")]
    public class WishlistController : ControllerBase
    {
        private readonly IWishlistService _wishlistService;

        public WishlistController(IWishlistService wishlistService)
        {
            _wishlistService = wishlistService;
        }

        [HttpPost("toggle")]
        public async Task<IActionResult> ToggleWishlist(
            [FromBody] ToggleWishlistDto request,
            CancellationToken cancellationToken = default)
        {
            var customerUserId = HttpContext.GetUserId();
            if (customerUserId <= 0)
            {
                return Unauthorized(ApiResponse<WishlistToggleResponseDto>.FailureResponse("Unauthorized. Valid JWT token required."));
            }

            var response = await _wishlistService.ToggleWishlistAsync(customerUserId, request, cancellationToken);
            return Ok(response);
        }

        [HttpGet("get")]
        [HttpGet]
        public async Task<IActionResult> GetCustomerWishlist(
            [FromQuery] GetWishlistQueryDto query,
            CancellationToken cancellationToken = default)
        {
            var customerUserId = HttpContext.GetUserId();
            if (customerUserId <= 0)
            {
                return Unauthorized(ApiResponse<List<CustomerWishlistItemDto>>.FailureResponse("Unauthorized. Valid JWT token required."));
            }

            query ??= new GetWishlistQueryDto();
            var response = await _wishlistService.GetCustomerWishlistAsync(customerUserId, query, cancellationToken);
            return Ok(response);
        }
    }
}
