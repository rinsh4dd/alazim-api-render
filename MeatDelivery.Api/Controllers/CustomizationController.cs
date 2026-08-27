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
        private readonly ICustomizationOptionService _customizationOptionService;
        private readonly ITemplateGroupMappingService _templateGroupMappingService;

        public CustomizationController(
            ICustomizationTemplateService customizationTemplateService,
            ICustomizationGroupService customizationGroupService,
            ICustomizationOptionService customizationOptionService,
            ITemplateGroupMappingService templateGroupMappingService)
        {
            _customizationTemplateService = customizationTemplateService;
            _customizationGroupService = customizationGroupService;
            _customizationOptionService = customizationOptionService;
            _templateGroupMappingService = templateGroupMappingService;
        }

        // =====================================================================
        // 1. CUSTOMIZATION TEMPLATES
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
        // 2. CUSTOMIZATION GROUPS
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

        // =====================================================================
        // 3. CUSTOMIZATION OPTIONS
        // =====================================================================

        [HttpPost("options/save")]
        public async Task<IActionResult> SaveCustomizationOption(
            [FromBody] SaveCustomizationOptionDto request,
            CancellationToken cancellationToken)
        {
            var response = await _customizationOptionService.SaveCustomizationOptionAsync(
                request,
                cancellationToken);

            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpGet("options/list")]
        public async Task<IActionResult> GetCustomizationOptions(
            [FromQuery] GetCustomizationOptionsQueryDto query,
            CancellationToken cancellationToken)
        {
            var response = await _customizationOptionService.GetCustomizationOptionsAsync(
                query,
                cancellationToken);

            return Ok(response);
        }

        // =====================================================================
        // 4. TEMPLATE GROUP MAPPINGS
        // =====================================================================

        [HttpPost("mappings/save")]
        public async Task<IActionResult> SaveTemplateGroupMapping(
            [FromBody] SaveTemplateGroupMappingDto request,
            CancellationToken cancellationToken)
        {
            var response = await _templateGroupMappingService.SaveTemplateGroupMappingAsync(
                request,
                cancellationToken);

            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpGet("mappings/list")]
        public async Task<IActionResult> GetTemplateGroupMappings(
            [FromQuery] GetTemplateGroupMappingsQueryDto query,
            CancellationToken cancellationToken)
        {
            var response = await _templateGroupMappingService.GetTemplateGroupMappingsAsync(
                query,
                cancellationToken);

            return Ok(response);
        }

        [HttpGet("product/{productId}")]
        public async Task<IActionResult> GetProductCustomizationHierarchy(
            [FromRoute] long productId,
            CancellationToken cancellationToken)
        {
            var response = await _customizationTemplateService.GetProductCustomizationHierarchyAsync(
                productId,
                cancellationToken);

            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }
    }
}
