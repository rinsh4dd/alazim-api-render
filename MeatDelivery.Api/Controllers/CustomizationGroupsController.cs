using System.Threading;
using System.Threading.Tasks;
using Asp.Versioning;
using Microsoft.AspNetCore.Mvc;
using MeatDelivery.Application.DTOs.Customization;
using MeatDelivery.Application.Interfaces.Customization;

namespace MeatDelivery.Api.Controllers.V1.Customization
{
    [ApiVersion("1.0")]
    [ApiController]
    [Route("api/v{version:apiVersion}/customization-groups")]
    public class CustomizationGroupsController : ControllerBase
    {
        private readonly ICustomizationGroupService _customizationGroupService;

        public CustomizationGroupsController(ICustomizationGroupService customizationGroupService)
        {
            _customizationGroupService = customizationGroupService;
        }

        [HttpPost("save")]
        public async Task<IActionResult> SaveCustomizationGroup(
            [FromBody] SaveCustomizationGroupDto request,
            CancellationToken cancellationToken)
        {
            var response = await _customizationGroupService.SaveCustomizationGroupAsync(
                request,
                cancellationToken);

            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }
    }
}
