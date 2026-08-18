using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Product;

namespace MeatDelivery.Application.Interfaces.Repositories.Product
{
    public interface IProductRepository
    {
        Task<ProductDto?> SaveProductFullAsync(SaveProductDto request, CancellationToken cancellationToken = default);
    }
}
