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
    [Route("api/v{version:apiVersion}/CustomizationTemplates")]
    public class CustomizationTemplatesController : ControllerBase
    {
        private readonly ICustomizationTemplateService _customizationTemplateService;

        public CustomizationTemplatesController(ICustomizationTemplateService customizationTemplateService)
        {
            _customizationTemplateService = customizationTemplateService;
        }

        [HttpPost("save")]
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

        [HttpGet("list")]
        public async Task<IActionResult> GetCustomizationTemplates(
            [FromQuery] GetCustomizationTemplatesQueryDto query,
            CancellationToken cancellationToken)
        {
            var response = await _customizationTemplateService.GetCustomizationTemplatesAsync(
                query,
                cancellationToken);

            return Ok(response);
        }
    }
}
