using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using MeatDelivery.Application.Interfaces.Product;

namespace MeatDelivery.Api.Controllers
{
    [ApiController]
    [Route("api/v1/measurement-units")]
    public class MeasurementUnitsController : ControllerBase
    {
        private readonly IMeasurementUnitService _measurementUnitService;

        public MeasurementUnitsController(IMeasurementUnitService measurementUnitService)
        {
            _measurementUnitService = measurementUnitService;
        }

        [HttpGet]
        public async Task<IActionResult> GetMeasurementUnits(
            [FromQuery] bool? onlyActive = true,
            CancellationToken cancellationToken = default)
        {
            var response = await _measurementUnitService.GetMeasurementUnitsAsync(onlyActive, cancellationToken);
            return Ok(response);
        }
    }
}
