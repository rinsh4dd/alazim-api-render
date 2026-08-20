using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Product;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Product
{
    public interface IProductService
    {
        Task<ApiResponse<ProductDto>> SaveProductAsync(SaveProductDto request, CancellationToken cancellationToken = default);
        Task<PagedResponse<List<ProductDto>>> GetProductsAsync(GetProductsQueryDto query, CancellationToken cancellationToken = default);
        Task<ApiResponse<List<ProductDto>>> GetFreshPicksAsync(CancellationToken cancellationToken = default);
        Task<ApiResponse<List<ProductDto>>> GetFeaturedProductsAsync(CancellationToken cancellationToken = default);
        Task<ApiResponse<ProductDto>> UpdateProductStatusAsync(UpdateProductStatusDto request, CancellationToken cancellationToken = default);
        Task<ApiResponse<ProductDto>> UpdateProductImageAsync(UpdateProductImageDto request, CancellationToken cancellationToken = default);
        Task<ApiResponse<ProductDto>> UpdateProductPriceAsync(UpdateProductPriceDto request, CancellationToken cancellationToken = default);
        Task<ApiResponse<List<ProductDto>>> ManageProductAttributesAsync(ManageAttributesDto request, CancellationToken cancellationToken = default);
    }
}
