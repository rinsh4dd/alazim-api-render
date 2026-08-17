using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Category;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Category;

namespace MeatDelivery.Infrastructure.Repositories.Catalog
{
    public class CategoryRepository : ICategoryRepository
    {
        private readonly IDapperRepository _dapperRepository;

        public CategoryRepository(IDapperRepository dapperRepository)
        {
            _dapperRepository = dapperRepository;
        }

        public async Task<CategoryDto?> SaveCategoryAsync(
            SaveCategoryDto request,
            CancellationToken cancellationToken = default)
        {
            return await _dapperRepository.QueryFirstOrDefaultAsync<CategoryDto>(
                "PR_SAVE_CATEGORY",
                new
                {
                    MODE = request.Mode.ToString(),
                    CATEGORY_ID = request.CategoryId,
                    PARENT_CATEGORY_ID = request.ParentCategoryId,
                    CATEGORY_CODE = request.CategoryCode,
                    CATEGORY_NAME_EN = request.CategoryNameEn,
                    CATEGORY_NAME_AR = request.CategoryNameAr,
                    DESCRIPTION_EN = request.DescriptionEn,
                    DESCRIPTION_AR = request.DescriptionAr,
                    IMAGE_URL = request.ImageUrl,
                    DISPLAY_ORDER = request.DisplayOrder,
                    IS_ACTIVE = request.IsActive,
                    IS_VISIBLE = request.IsVisible
                }
            );
        }
    }
}