using System.Threading;
using System.Threading.Tasks;
using Asp.Versioning;
using Microsoft.AspNetCore.Mvc;
using MeatDelivery.Application.Interfaces.Company;

namespace MeatDelivery.Api.Controllers
{
    [ApiController]
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/delivery")]
    public class DeliveryController : BaseApiController
    {
        private readonly IDeliveryService _deliveryService;

        public DeliveryController(IDeliveryService deliveryService)
        {
            _deliveryService = deliveryService;
        }

        [HttpGet("available-dates")]
        [HttpGet]
        public async Task<IActionResult> GetAvailableDeliveryDates(CancellationToken cancellationToken = default)
        {
            var response = await _deliveryService.GetAvailableDeliveryDatesAsync(cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }
    }
}
