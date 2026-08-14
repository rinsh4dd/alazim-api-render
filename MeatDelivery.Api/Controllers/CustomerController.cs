using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MeatDelivery.Api.Extensions;
using MeatDelivery.Application.DTOs.Addresses;
using MeatDelivery.Application.Interfaces.Customer;
using System.Threading;
using System.Threading.Tasks;

namespace MeatDelivery.Api.Controllers
{
    [ApiController]
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/customer")]
    [Authorize]
    public class CustomerController : BaseApiController
    {
        private readonly ICustomerService _customerService;

        public CustomerController(ICustomerService customerService)
        {
            _customerService = customerService;
        }

        [HttpGet("address")]
        public async Task<IActionResult> GetCustomerAddress(
            [FromQuery] GetCustomerAddressQueryDto query,
            CancellationToken cancellationToken)
        {
            var customerUserId = HttpContext.GetUserId();
            var response = await _customerService.GetCustomerAddressAsync(query, customerUserId, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpPost("address")]
        public async Task<IActionResult> SaveCustomerAddress(
            [FromBody] SaveCustomerAddressDto request,
            CancellationToken cancellationToken)
        {
            var customerUserId = HttpContext.GetUserId();
            var response = await _customerService.SaveCustomerAddressAsync(request, customerUserId, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpPost("address/default")]
        public async Task<IActionResult> SetDefaultCustomerAddress(
            [FromBody] SetDefaultCustomerAddressDto request,
            CancellationToken cancellationToken)
        {
            var customerUserId = HttpContext.GetUserId();
            var response = await _customerService.SetDefaultCustomerAddressAsync(request.AddressId, customerUserId, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }
    }
}
