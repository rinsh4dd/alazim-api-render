using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Product;

namespace MeatDelivery.Application.Interfaces.Repositories.Product
{
    public interface IProductRepository
    {
        Task<ProductDto?> SaveProductMasterAsync(SaveProductDto request, CancellationToken cancellationToken = default);
        Task SyncProductWeightOptionsAndPricesAsync(long productId, List<SaveProductWeightOptionDto> weightOptions, CancellationToken cancellationToken = default);
        Task SyncProductImagesAsync(long productId, List<SaveProductImageDto> images, CancellationToken cancellationToken = default);
        Task<ProductDto?> GetProductByIdAsync(long productId, CancellationToken cancellationToken = default);
    }
}
