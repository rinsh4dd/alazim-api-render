using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using MeatDelivery.Application.DTOs.Product;
using MeatDelivery.Application.Interfaces.Product;

namespace MeatDelivery.Api.Controllers
{
    [ApiController]
    [Route("api/v1/admin/products")]
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
            var response = await _productService.GetProductsAsync(query, cancellationToken);
            return Ok(response);
        }

        [HttpGet("/api/v1/FreshPicks")]

        public async Task<IActionResult> GetFreshPicks(CancellationToken cancellationToken = default)
        {
            var response = await _productService.GetFreshPicksAsync(cancellationToken);
            return Ok(response);
        }

        [HttpPost("status")]
        public async Task<IActionResult> UpdateProductStatus(
            [FromBody] UpdateProductStatusDto request,
            CancellationToken cancellationToken = default)
        {
            var response = await _productService.UpdateProductStatusAsync(request, cancellationToken);
            return Ok(response);
        }

        [HttpPost("image")]
        public async Task<IActionResult> UpdateProductImage(
            [FromBody] UpdateProductImageDto request,
            CancellationToken cancellationToken = default)
        {
            var response = await _productService.UpdateProductImageAsync(request, cancellationToken);
            return Ok(response);
        }
    }
}
