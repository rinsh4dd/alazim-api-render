using System.Threading;
using System.Threading.Tasks;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MeatDelivery.Api.Extensions;
using MeatDelivery.Application.DTOs.Order;
using MeatDelivery.Application.Interfaces.Order;

namespace MeatDelivery.Api.Controllers
{
    [ApiController]
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/orders")]
    [Authorize]
    public class OrdersController : BaseApiController
    {
        private readonly IOrderService _orderService;

        public OrdersController(IOrderService orderService)
        {
            _orderService = orderService;
        }



        /// <summary>
        /// Places an order converting the active cart into a finalized order.
        /// </summary>
        [HttpPost("place")]
        public async Task<IActionResult> PlaceOrder(
            [FromBody] PlaceOrderRequestDto request,
            CancellationToken cancellationToken = default)
        {
            var customerUserId = HttpContext.GetUserId();
            var response = await _orderService.PlaceOrderAsync(customerUserId, request, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;

            if (!response.Success)
            {
                return BadRequest(response);
            }

            return Ok(response);
        }
    }
}
