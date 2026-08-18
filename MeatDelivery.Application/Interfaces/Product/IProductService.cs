using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Product;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Product
{
    public interface IProductService
    {
        Task<ApiResponse<ProductDto>> SaveProductAsync(SaveProductDto request, CancellationToken cancellationToken = default);
    }
}
