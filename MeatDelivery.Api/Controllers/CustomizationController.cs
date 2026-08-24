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
    [Route("api/v{version:apiVersion}/customization")]
    public class CustomizationController : ControllerBase
    {
        private readonly ICustomizationTemplateService _customizationTemplateService;
        private readonly ICustomizationGroupService _customizationGroupService;

        public CustomizationController(
            ICustomizationTemplateService customizationTemplateService,
            ICustomizationGroupService customizationGroupService)
        {
            _customizationTemplateService = customizationTemplateService;
            _customizationGroupService = customizationGroupService;
        }

        // =====================================================================
        // CUSTOMIZATION TEMPLATES
        // =====================================================================

        [HttpPost("templates/save")]
        public async Task<IActionResult> SaveCustomizationTemplate(
            [FromBody] SaveCustomizationTemplateDto request,
            CancellationToken cancellationToken)
        {
            var response = await _customizationTemplateService.SaveCustomizationTemplateAsync(
                request,
                cancellationToken);

            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpGet("templates/list")]
        public async Task<IActionResult> GetCustomizationTemplates(
            [FromQuery] GetCustomizationTemplatesQueryDto query,
            CancellationToken cancellationToken)
        {
            var response = await _customizationTemplateService.GetCustomizationTemplatesAsync(
                query,
                cancellationToken);

            return Ok(response);
        }

        // =====================================================================
        // CUSTOMIZATION GROUPS
        // =====================================================================

        [HttpPost("groups/save")]
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

        [HttpGet("groups/list")]
        public async Task<IActionResult> GetCustomizationGroups(
            [FromQuery] GetCustomizationGroupsQueryDto query,
            CancellationToken cancellationToken)
        {
            var response = await _customizationGroupService.GetCustomizationGroupsAsync(
                query,
                cancellationToken);

            return Ok(response);
        }
    }
}
