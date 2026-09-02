using System.Threading;
using System.Threading.Tasks;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MeatDelivery.Api.Extensions;
using MeatDelivery.Application.DTOs.Cart;
using MeatDelivery.Application.Interfaces.Cart;

namespace MeatDelivery.Api.Controllers
{
    [ApiController]
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/cart")]
    [Authorize]
    public class CartController : BaseApiController
    {
        private readonly ICartService _cartService;

        public CartController(ICartService cartService)
        {
            _cartService = cartService;
        }

        [HttpGet]
        public async Task<IActionResult> GetActiveCart(CancellationToken cancellationToken)
        {
            var customerUserId = HttpContext.GetUserId();
            var response = await _cartService.GetActiveCartAsync(customerUserId, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpPost("items/add")]
        public async Task<IActionResult> AddToCart(
            [FromBody] AddCartItemDto request,
            CancellationToken cancellationToken)
        {
            var customerUserId = HttpContext.GetUserId();
            var response = await _cartService.AddToCartAsync(customerUserId, request, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpPost("items/update-quantity")]
        public async Task<IActionResult> UpdateQuantity(
            [FromBody] UpdateCartItemQuantityDto request,
            CancellationToken cancellationToken)
        {
            var customerUserId = HttpContext.GetUserId();
            var response = await _cartService.UpdateQuantityAsync(customerUserId, request, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpPost("items/update-customization")]
        public async Task<IActionResult> UpdateCustomization(
            [FromBody] UpdateCartItemCustomizationDto request,
            CancellationToken cancellationToken)
        {
            var customerUserId = HttpContext.GetUserId();
            var response = await _cartService.UpdateCustomizationAsync(customerUserId, request, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpPost("items/remove")]
        public async Task<IActionResult> RemoveCartItem(
            [FromBody] RemoveCartItemDto request,
            CancellationToken cancellationToken)
        {
            var customerUserId = HttpContext.GetUserId();
            var response = await _cartService.RemoveCartItemAsync(customerUserId, request, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpPost("clear")]
        public async Task<IActionResult> ClearCart(CancellationToken cancellationToken)
        {
            var customerUserId = HttpContext.GetUserId();
            var response = await _cartService.ClearCartAsync(customerUserId, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }
    }
}
