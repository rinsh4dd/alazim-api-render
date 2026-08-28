using System.Threading;
using System.Threading.Tasks;
using Asp.Versioning;
using Microsoft.AspNetCore.Mvc;
using MeatDelivery.Api.Extensions;
using MeatDelivery.Application.DTOs.Cart;
using MeatDelivery.Application.Interfaces.Cart;

namespace MeatDelivery.Api.Controllers
{
    [ApiController]
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/cart")]
    public class CartController : BaseApiController
    {
        private readonly ICartService _cartService;

        public CartController(ICartService cartService)
        {
            _cartService = cartService;
        }

        /// <summary>
        /// Dedicated API to Add a Product (with selected Customization Options & Special Instructions) to Customer's Cart.
        /// </summary>
        [HttpPost("items/add")]
        public async Task<IActionResult> AddToCart(
            [FromBody] AddCartItemDto request,
            CancellationToken cancellationToken)
        {
            var customerUserId = HttpContext.GetUserId();
            var response = await _cartService.AddToCartAsync(customerUserId, request);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }
    }
}
