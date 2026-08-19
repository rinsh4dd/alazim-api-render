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
    }
}
