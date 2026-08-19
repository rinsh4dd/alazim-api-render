using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MeatDelivery.Application.DTOs.Product;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Data;
using MeatDelivery.Application.Interfaces.Repositories.Product;

namespace MeatDelivery.Infrastructure.Repositories.Catalog
{
    public class ProductRepository : IProductRepository
    {
        private readonly IDapperRepository _dapperRepository;

        public ProductRepository(IDapperRepository dapperRepository)
        {
            _dapperRepository = dapperRepository;
        }

        public async Task<ProductDto?> SaveProductAsync(SaveProductDto request, CancellationToken cancellationToken = default)
        {
            return await _dapperRepository.QueryFirstOrDefaultAsync<ProductDto>(
                "dbo.PR_SAVE_PRODUCT",
                new
                {
                    MODE = request.Mode.ToString(),
                    PRODUCT_ID = request.ProductId,
                    CATEGORY_ID = request.CategoryId,
                    PRODUCT_NAME_EN = request.ProductNameEn,
                    PRODUCT_NAME_AR = request.ProductNameAr,
                    DESCRIPTION_EN = request.DescriptionEn,
                    DESCRIPTION_AR = request.DescriptionAr,
                    IS_CUSTOMIZABLE = request.IsCustomizable,
                    CUSTOMIZATION_TEMPLATE_ID = request.CustomizationTemplateId,
                    UNIT_ID = request.UnitId,
                    DISCOUNT_PERCENTAGE = request.DiscountPercentage,
                    INITIAL_STOCK_COUNT = request.InitialStockCount,
                    PRICE = request.Price,
                    PRIMARY_URL = request.PrimaryUrl,
                    SECONDARY_URL = request.SecondaryUrl,
                    TERTIARY_URL = request.TertiaryUrl,
                    IS_FEATURED = request.IsFeatured,
                    IS_ACTIVE = request.IsActive
                }
            );
        }

        public async Task<(List<ProductDto> Items, int TotalRecords)> GetProductsAsync(GetProductsQueryDto query, CancellationToken cancellationToken = default)
        {
            return await _dapperRepository.QueryMultipleAsync(
                "dbo.PR_GET_PRODUCTS",
                async grid =>
                {
                    var totalRecords = (await grid.ReadAsync<int>()).FirstOrDefault();
                    var items = (await grid.ReadAsync<ProductDto>()).ToList();
                    return (items, totalRecords);
                },
                new
                {
                    PRODUCT_ID = query.ProductId,
                    CATEGORY_ID = query.CategoryId,
                    SEARCH_TERM = query.SearchTerm,
                    IS_FEATURED = query.IsFeatured,
                    IS_NEW_ARRIVAL = query.IsNewArrival,
                    IS_ACTIVE = query.IsActive,
                    IS_DELETED = query.IsDeleted,
                    PAGE_NUMBER = query.PageNumber,
                    PAGE_SIZE = query.PageSize
                }
            );
        }

        public async Task<ProductDto?> UpdateProductStatusAsync(UpdateProductStatusDto request, CancellationToken cancellationToken = default)
        {
            return await _dapperRepository.QueryMultipleAsync(
                "dbo.PR_UPDATE_PRODUCT_STATUS",
                async grid =>
                {
                    var totalRecords = (await grid.ReadAsync<int>()).FirstOrDefault();
                    var items = (await grid.ReadAsync<ProductDto>()).ToList();
                    return items.FirstOrDefault();
                },
                new
                {
                    PRODUCT_ID = request.ProductId
                }
            );
        }

        public async Task<ProductDto?> UpdateProductImageAsync(UpdateProductImageDto request, CancellationToken cancellationToken = default)
        {
            return await _dapperRepository.QueryMultipleAsync(
                "dbo.PR_UPDATE_PRODUCT_IMAGE",
                async grid =>
                {
                    var totalRecords = (await grid.ReadAsync<int>()).FirstOrDefault();
                    var items = (await grid.ReadAsync<ProductDto>()).ToList();
                    return items.FirstOrDefault();
                },
                new
                {
                    PRODUCT_ID = request.ProductId,
                    PRIMARY_URL = request.PrimaryUrl,
                    SECONDARY_URL = request.SecondaryUrl,
                    TERTIARY_URL = request.TertiaryUrl
                }
            );
        }
    }
}
