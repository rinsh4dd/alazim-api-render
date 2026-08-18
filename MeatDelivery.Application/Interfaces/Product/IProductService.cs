using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Product;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Product
{
    public interface IProductService
    {
        Task<ApiResponse<ProductDto>> SaveProductAsync(SaveProductDto request, CancellationToken cancellationToken = default);
        Task<ApiResponse<ProductDto>> GetProductByIdAsync(long productId, CancellationToken cancellationToken = default);
    }
}
