using System.Threading;
using System.Threading.Tasks;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MeatDelivery.Application.DTOs.Company;
using MeatDelivery.Application.Interfaces.Company;

namespace MeatDelivery.Api.Controllers
{
    [ApiController]
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/holidays")]
    public class CompanyHolidaysController : BaseApiController
    {
        private readonly ICompanyHolidayService _companyHolidayService;

        public CompanyHolidaysController(ICompanyHolidayService companyHolidayService)
        {
            _companyHolidayService = companyHolidayService;
        }

        [HttpGet]
        public async Task<IActionResult> GetHolidays(
            [FromQuery] GetCompanyHolidaysQueryDto query,
            CancellationToken cancellationToken)
        {
            var response = await _companyHolidayService.GetCompanyHolidaysAsync(query, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpPost("save")]
        [Authorize(Roles = "SUPER_ADMIN,ADMIN")]
        public async Task<IActionResult> SaveHoliday(
            [FromBody] SaveCompanyHolidayDto request,
            CancellationToken cancellationToken)
        {
            var response = await _companyHolidayService.SaveCompanyHolidayAsync(request, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }
    }
}
