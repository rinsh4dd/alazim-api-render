using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Dapper;
using MeatDelivery.Application.DTOs.Category;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Category;

namespace MeatDelivery.Infrastructure.Repositories.Catalog
{
    public class CategoryRepository : ICategoryRepository
    {
        private readonly IDapperRepository _dapperRepository;
        private readonly IDbConnectionFactory _connectionFactory;

        public CategoryRepository(
            IDapperRepository dapperRepository,
            IDbConnectionFactory connectionFactory)
        {
            _dapperRepository = dapperRepository;
            _connectionFactory = connectionFactory;
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
                    CATEGORY_CODE = request.CategoryCode,
                    CATEGORY_NAME_EN = request.CategoryNameEn,
                    CATEGORY_NAME_AR = request.CategoryNameAr,
                    DESCRIPTION_EN = request.DescriptionEn,
                    DESCRIPTION_AR = request.DescriptionAr,
                    IMAGE_URL = request.ImageUrl,
                    DISPLAY_ORDER = request.DisplayOrder,
                    IS_ACTIVE = request.IsActive
                }
            );
        }

        public async Task<(List<CategoryDto> Items, int TotalRecords)> GetCategoriesAsync(
            GetCategoriesQueryDto query,
            CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();
            using var multi = await connection.QueryMultipleAsync(
                "dbo.PR_GET_CATEGORIES",
                new
                {
                    PAGE_NUMBER = query.PageNumber,
                    PAGE_SIZE = query.PageSize,
                    SEARCH_TERM = query.SearchTerm,
                    CATEGORY_ID = query.CategoryId,
                    IS_ACTIVE = query.IsActive
                },
                commandType: CommandType.StoredProcedure);

            int totalRecords = await multi.ReadSingleAsync<int>();
            var items = (await multi.ReadAsync<CategoryDto>()).ToList();

            return (items, totalRecords);
        }
    }
}