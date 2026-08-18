using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using MeatDelivery.Application.DTOs.Product;
using MeatDelivery.Application.Interfaces.Product;

namespace MeatDelivery.Api.Controllers
{
    [ApiController]
    [Route("api/v1/products")]
    public class ProductsController : ControllerBase
    {
        private readonly IProductService _productService;

        public ProductsController(IProductService productService)
        {
            _productService = productService;
        }

        [HttpPost("save")]
        public async Task<IActionResult> SaveProduct(
            [FromBody] SaveProductDto request,
            CancellationToken cancellationToken = default)
        {
            var response = await _productService.SaveProductAsync(request, cancellationToken);
            return Ok(response);
        }

        [HttpPost("get")]
        public async Task<IActionResult> GetProducts(
            [FromBody] GetProductsQueryDto query,
            CancellationToken cancellationToken = default)
        {
            var response = await _productService.GetProductsAsync(query ?? new GetProductsQueryDto(), cancellationToken);
            return Ok(response);
        }
    }
}
