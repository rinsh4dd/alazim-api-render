using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Dapper;
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
                    IS_PREORDERABLE = request.IsPreorderable,
                    IS_NEW_ARRIVAL = request.IsNewArrival,
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
                    IS_PREORDERABLE = query.IsPreorderable,
                    IS_ACTIVE = query.IsActive,
                    IS_DELETED = query.IsDeleted,
                    PAGE_NUMBER = query.PageNumber,
                    PAGE_SIZE = query.PageSize
                }
            );
        }

        public async Task<List<ProductDto>> GetFreshPicksProductsAsync(CancellationToken cancellationToken = default)
        {
            var items = await _dapperRepository.QueryAsync<ProductDto>(
                "dbo.PR_GET_FRESH_PICKS_PRODUCTS"
            );
            return items.ToList();
        }

        public async Task<List<ProductDto>> GetFeaturedProductsAsync(CancellationToken cancellationToken = default)
        {
            var items = await _dapperRepository.QueryAsync<ProductDto>(
                "dbo.PR_GET_FEATURED_PRODUCTS"
            );
            return items.ToList();
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

        public async Task<ProductDto?> UpdateProductPriceAsync(UpdateProductPriceDto request, CancellationToken cancellationToken = default)
        {
            var items = await _dapperRepository.QueryAsync<ProductDto>(
                "dbo.PR_UPDATE_PRODUCT_PRICE",
                new
                {
                    PRODUCT_ID = request.ProductId,
                    PRICE = request.Price,
                    DISCOUNT_PERCENTAGE = request.DiscountPercentage
                }
            );
            return items.FirstOrDefault();
        }

        public async Task<(List<ProductPriceHistoryDto> Items, int TotalRecords)> GetPriceHistoryAsync(GetPriceHistoryQueryDto query, CancellationToken cancellationToken = default)
        {
            return await _dapperRepository.QueryMultipleAsync(
                "dbo.PR_GET_PRODUCT_PRICE_HISTORY",
                async grid =>
                {
                    var totalRecords = (await grid.ReadAsync<int>()).FirstOrDefault();
                    var items = (await grid.ReadAsync<ProductPriceHistoryDto>()).ToList();
                    return (items, totalRecords);
                },
                new
                {
                    PRODUCT_ID = query.ProductId,
                    PAGE_NUMBER = query.PageNumber,
                    PAGE_SIZE = query.PageSize
                }
            );
        }

        public async Task<List<ProductDto>> ManageProductAttributesAsync(ManageAttributesDto request, CancellationToken cancellationToken = default)
        {
            var dataTable = new DataTable();
            dataTable.Columns.Add("PRODUCT_ID", typeof(long));

            if (request.ProductIds != null)
            {
                foreach (var id in request.ProductIds.Distinct())
                {
                    dataTable.Rows.Add(id);
                }
            }

            var parameters = new DynamicParameters();
            parameters.Add("MODE", request.Mode.ToString());
            parameters.Add("PRODUCT_IDS", dataTable.AsTableValuedParameter("dbo.PRODUCT_ID_LIST"));
            parameters.Add("VALUE", request.Value);

            var items = await _dapperRepository.QueryAsync<ProductDto>(
                "dbo.PR_MANAGE_PRODUCT_ATTRIBUTES",
                parameters
            );
            return items.ToList();
        }
    }
}
