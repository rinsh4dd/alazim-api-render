using MeatDelivery.Application.DTOs.Category;

namespace MeatDelivery.Application.Interfaces.Repositories.Category
{
    public interface ICategoryRepository
    {
        Task<CategoryDto?> SaveCategoryAsync(SaveCategoryDto request, CancellationToken cancellationToken = default);
    }
}