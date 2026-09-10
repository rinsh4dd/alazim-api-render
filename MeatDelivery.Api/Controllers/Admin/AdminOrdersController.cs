using System.Threading;
using System.Threading.Tasks;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MeatDelivery.Application.DTOs.Order;
using MeatDelivery.Application.Interfaces.Order;

namespace MeatDelivery.Api.Controllers.Admin
{
    [ApiController]
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/admin/orders")]
    [Authorize]
    public class AdminOrdersController : BaseApiController
    {
        private readonly IOrderService _orderService;

        public AdminOrdersController(IOrderService orderService)
        {
            _orderService = orderService;
        }

        [HttpGet]
        public async Task<IActionResult> GetAdminOrders(
            [FromQuery] GetAdminOrdersQueryDto query,
            CancellationToken cancellationToken = default)
        {
            var response = await _orderService.GetAdminOrdersAsync(query, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpGet("track/{orderId}")]
        public async Task<IActionResult> TrackAdminOrder(
            [FromRoute] long orderId,
            CancellationToken cancellationToken = default)
        {
            var response = await _orderService.TrackOrderAsync(orderId, customerUserId: null, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpPost("updateStatus")]
        public async Task<IActionResult> UpdateOrderStatus(
            [FromBody] UpdateOrderStatusDto request,
            CancellationToken cancellationToken = default)
        {
            var response = await _orderService.UpdateOrderStatusAsync(request, adminUserId: null, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpPost("cancel")]
        public async Task<IActionResult> CancelOrder(
            [FromBody] CancelOrderDto request,
            CancellationToken cancellationToken = default)
        {
            var response = await _orderService.CancelOrderAsync(request, customerUserId: null, adminUserId: null, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }
    }
}
