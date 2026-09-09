using System.Threading;
using System.Threading.Tasks;
using Asp.Versioning;
using Microsoft.AspNetCore.Mvc;
using MeatDelivery.Application.DTOs.Product;
using MeatDelivery.Application.Interfaces.Product;

namespace MeatDelivery.Api.Controllers
{
    [ApiController]
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/admin/products")]
    public class ProductsController : BaseApiController
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
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpPost("get")]
        public async Task<IActionResult> GetProducts(
            [FromBody] GetProductsQueryDto query,
            CancellationToken cancellationToken = default)
        {
            var response = await _productService.GetProductsAsync(query, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpGet("/api/v1/FreshPicks")]
        public async Task<IActionResult> GetFreshPicks(CancellationToken cancellationToken = default)
        {
            var response = await _productService.GetFreshPicksAsync(cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpGet("/api/v1/FeaturedProducts")]
        public async Task<IActionResult> GetFeaturedProducts(CancellationToken cancellationToken = default)
        {
            var response = await _productService.GetFeaturedProductsAsync(cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpPost("status")]
        public async Task<IActionResult> UpdateProductStatus(
            [FromBody] UpdateProductStatusDto request,
            CancellationToken cancellationToken = default)
        {
            var response = await _productService.UpdateProductStatusAsync(request, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpPost("updateImage")]
        public async Task<IActionResult> UpdateProductImage(
            [FromBody] UpdateProductImageDto request,
            CancellationToken cancellationToken = default)
        {
            var response = await _productService.UpdateProductImageAsync(request, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpPost("updatePrice")]
        public async Task<IActionResult> UpdateProductPrice(
            [FromBody] UpdateProductPriceDto request,
            CancellationToken cancellationToken = default)
        {
            var response = await _productService.UpdateProductPriceAsync(request, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpGet("priceHistory")]
        public async Task<IActionResult> GetPriceHistory(
            [FromQuery] GetPriceHistoryQueryDto query,
            CancellationToken cancellationToken = default)
        {
            var response = await _productService.GetPriceHistoryAsync(query, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        [HttpPost("manageAttributes")]
        public async Task<IActionResult> ManageAttributes(
            [FromBody] ManageAttributesDto request,
            CancellationToken cancellationToken = default)
        {
            var response = await _productService.ManageProductAttributesAsync(request, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }
    }
}
