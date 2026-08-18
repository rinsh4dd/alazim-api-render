using MeatDelivery.Application.DTOs.Category;
using MeatDelivery.Shared.Responses;

namespace MeatDelivery.Application.Interfaces.Category
{
    public interface ICategoryService
    {
        Task<ApiResponse<CategoryDto>> SaveCategoryAsync(SaveCategoryDto request,CancellationToken cancellationToken = default);
        Task<PagedResponse<List<CategoryDto>>> GetCategoriesAsync(GetCategoriesQueryDto query, CancellationToken cancellationToken = default);
    }
}