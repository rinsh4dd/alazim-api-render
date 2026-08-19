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
    }
}
