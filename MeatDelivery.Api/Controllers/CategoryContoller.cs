using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using MeatDelivery.Application.DTOs.Category;
using MeatDelivery.Application.Interfaces.Category;

namespace MeatDelivery.Api.Controllers.V1.Catalog
{
    [ApiController]
    [Route("api/v1/categories")]
    public class CategoriesController : ControllerBase
    {
        private readonly ICategoryService _categoryService;

        public CategoriesController(ICategoryService categoryService)
        {
            _categoryService = categoryService;
        }

        [HttpPost("save")]
        public async Task<IActionResult> SaveCategory(
            [FromBody] SaveCategoryDto request,
            CancellationToken cancellationToken)
        {
            var response = await _categoryService.SaveCategoryAsync(
                request,
                cancellationToken);

            return Ok(response);
        }
    }
}