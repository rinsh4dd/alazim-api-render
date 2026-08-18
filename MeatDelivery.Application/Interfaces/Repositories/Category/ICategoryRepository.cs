using MeatDelivery.Application.DTOs.Category;

namespace MeatDelivery.Application.Interfaces.Repositories.Category
{
    public interface ICategoryRepository
    {
        Task<CategoryDto?> SaveCategoryAsync(SaveCategoryDto request, CancellationToken cancellationToken = default);
        Task<(List<CategoryDto> Items, int TotalRecords)> GetCategoriesAsync(GetCategoriesQueryDto query, CancellationToken cancellationToken = default);
    }
}