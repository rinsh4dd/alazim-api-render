using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Product;

namespace MeatDelivery.Application.Interfaces.Repositories.Product
{
    public interface IProductRepository
    {
        Task<ProductDto?> SaveProductAsync(SaveProductDto request, CancellationToken cancellationToken = default);
        Task<(List<ProductDto> Items, int TotalRecords)> GetProductsAsync(GetProductsQueryDto query, CancellationToken cancellationToken = default);
        Task<List<ProductDto>> GetFreshPicksProductsAsync(CancellationToken cancellationToken = default);
        Task<List<ProductDto>> GetFeaturedProductsAsync(CancellationToken cancellationToken = default);
        Task<ProductDto?> UpdateProductStatusAsync(UpdateProductStatusDto request, CancellationToken cancellationToken = default);
        Task<ProductDto?> UpdateProductImageAsync(UpdateProductImageDto request, CancellationToken cancellationToken = default);
        Task<List<ProductDto>> ManageProductAttributesAsync(ManageAttributesDto request, CancellationToken cancellationToken = default);
    }
}
