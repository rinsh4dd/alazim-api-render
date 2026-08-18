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
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Infrastructure.Repositories.Catalog
{
    public class ProductRepository : IProductRepository
    {
        private readonly IDapperRepository _dapperRepository;
        private readonly IDbConnectionFactory _connectionFactory;

        public ProductRepository(
            IDapperRepository dapperRepository,
            IDbConnectionFactory connectionFactory)
        {
            _dapperRepository = dapperRepository;
            _connectionFactory = connectionFactory;
        }

        public async Task<ProductDto?> SaveProductFullAsync(SaveProductDto request, CancellationToken cancellationToken = default)
        {
            // 1. Save Master Product via Stored Procedure dbo.PR_SAVE_PRODUCT (with child cleanup flags)
            var productMaster = await _dapperRepository.QueryFirstOrDefaultAsync<ProductDto>(
                "dbo.PR_SAVE_PRODUCT",
                new
                {
                    MODE = request.Mode.ToString(),
                    PRODUCT_ID = request.ProductId,
                    CATEGORY_ID = request.CategoryId,
                    DOC_NO = request.DocNo,
                    DOC_TYPE = string.IsNullOrWhiteSpace(request.DocType) ? "PRD1" : request.DocType,
                    PRODUCT_NAME_EN = request.ProductNameEn,
                    PRODUCT_NAME_AR = request.ProductNameAr,
                    DESCRIPTION_EN = request.DescriptionEn,
                    DESCRIPTION_AR = request.DescriptionAr,
                    COUNTRY_OF_ORIGIN = request.CountryOfOrigin,
                    IS_HALAL_CERTIFIED = request.IsHalalCertified,
                    HALAL_CERTIFICATE_NO = request.HalalCertificateNo,
                    HALAL_CERTIFICATE_URL = request.HalalCertificateUrl,
                    NUTRITION_INFORMATION_EN = request.NutritionInformationEn,
                    NUTRITION_INFORMATION_AR = request.NutritionInformationAr,
                    STORAGE_INSTRUCTIONS_EN = request.StorageInstructionsEn,
                    STORAGE_INSTRUCTIONS_AR = request.StorageInstructionsAr,
                    IS_CUSTOMIZABLE = request.IsCustomizable,
                    CUSTOMIZATION_TEMPLATE_ID = request.CustomizationTemplateId,
                    DISPLAY_ORDER = request.DisplayOrder,
                    IS_FEATURED = request.IsFeatured,
                    IS_BESTSELLER = request.IsBestseller,
                    IS_ACTIVE = request.IsActive,
                    CLEAR_WEIGHTS = request.WeightOptions != null ? 1 : 0,
                    CLEAR_IMAGES = request.Images != null ? 1 : 0
                }
            );

            if (request.Mode == Mode.DELETE || productMaster == null)
            {
                return productMaster;
            }

            long productId = productMaster.ProductId;

            if (request.WeightOptions != null || request.Images != null)
            {
                using var connection = _connectionFactory.CreateConnection();
                if (connection.State != ConnectionState.Open)
                    connection.Open();

                using (var transaction = connection.BeginTransaction())
                {
                    try
                    {
                        // 2. Save Weight Options & Prices via Stored Procedure
                        if (request.WeightOptions != null)
                        {
                            foreach (var option in request.WeightOptions)
                            {
                                await connection.ExecuteAsync(
                                    "dbo.PR_SAVE_PRODUCT_WEIGHT_OPTION",
                                    new
                                    {
                                        PRODUCT_ID = productId,
                                        UNIT_ID = option.UnitId,
                                        UNIT_VALUE = option.UnitValue,
                                        IS_CUSTOM_WEIGHT = option.IsCustomWeight,
                                        MIN_WEIGHT = option.MinWeight,
                                        MAX_WEIGHT = option.MaxWeight,
                                        MIN_ORDER_QUANTITY = option.MinOrderQuantity,
                                        MAX_ORDER_QUANTITY = option.MaxOrderQuantity,
                                        QUANTITY_INCREMENT = option.QuantityIncrement,
                                        IS_DEFAULT = option.IsDefault,
                                        DISPLAY_ORDER = option.DisplayOrder,
                                        IS_ACTIVE = option.IsActive,
                                        PRICE_TYPE = string.IsNullOrWhiteSpace(option.PriceType) ? "FIXED" : option.PriceType,
                                        REGULAR_PRICE = option.RegularPrice,
                                        DISCOUNT_PRICE = option.DiscountPrice,
                                        CURRENCY_CODE = string.IsNullOrWhiteSpace(option.CurrencyCode) ? "AED" : option.CurrencyCode
                                    },
                                    transaction,
                                    commandType: CommandType.StoredProcedure);
                            }
                        }

                        // 3. Save Product Images via Stored Procedure
                        if (request.Images != null)
                        {
                            foreach (var img in request.Images)
                            {
                                await connection.ExecuteAsync(
                                    "dbo.PR_SAVE_PRODUCT_IMAGE",
                                    new
                                    {
                                        PRODUCT_ID = productId,
                                        IMAGE_URL = img.ImageUrl,
                                        IS_PRIMARY = img.IsPrimary,
                                        DISPLAY_ORDER = img.DisplayOrder,
                                        IS_ACTIVE = img.IsActive
                                    },
                                    transaction,
                                    commandType: CommandType.StoredProcedure);
                            }
                        }

                        transaction.Commit();
                    }
                    catch
                    {
                        transaction.Rollback();
                        throw;
                    }
                }

                // 4. Read back saved WeightOptions and Images to populate productMaster response
                const string querySql = @"
                    SELECT
                        w.PRODUCT_WEIGHT_OPTION_ID AS ProductWeightOptionId,
                        w.PRODUCT_ID AS ProductId,
                        w.UNIT_ID AS UnitId,
                        u.UNIT AS Unit,
                        u.UNIT_DESCRIPTION AS UnitDescription,
                        w.UNIT_VALUE AS UnitValue,
                        w.IS_CUSTOM_WEIGHT AS IsCustomWeight,
                        w.MIN_WEIGHT AS MinWeight,
                        w.MAX_WEIGHT AS MaxWeight,
                        w.MIN_ORDER_QUANTITY AS MinOrderQuantity,
                        w.MAX_ORDER_QUANTITY AS MaxOrderQuantity,
                        w.QUANTITY_INCREMENT AS QuantityIncrement,
                        w.IS_DEFAULT AS IsDefault,
                        w.DISPLAY_ORDER AS DisplayOrder,
                        w.IS_ACTIVE AS IsActive,
                        pr.PRODUCT_PRICE_ID AS ProductPriceId,
                        pr.PRICE_TYPE AS PriceType,
                        pr.REGULAR_PRICE AS RegularPrice,
                        pr.DISCOUNT_PRICE AS DiscountPrice,
                        pr.CURRENCY_CODE AS CurrencyCode
                    FROM dbo.PRODUCT_WEIGHT_OPTIONS w
                    INNER JOIN dbo.MEASUREMENT_UNITS u ON w.UNIT_ID = u.UNIT_ID
                    LEFT JOIN dbo.PRODUCT_PRICES pr ON w.PRODUCT_WEIGHT_OPTION_ID = pr.PRODUCT_WEIGHT_OPTION_ID
                    WHERE w.PRODUCT_ID = @ProductId
                    ORDER BY w.DISPLAY_ORDER ASC, w.PRODUCT_WEIGHT_OPTION_ID ASC;

                    SELECT
                        PRODUCT_IMAGE_ID AS ProductImageId,
                        PRODUCT_ID AS ProductId,
                        IMAGE_URL AS ImageUrl,
                        IS_PRIMARY AS IsPrimary,
                        DISPLAY_ORDER AS DisplayOrder,
                        IS_ACTIVE AS IsActive
                    FROM dbo.PRODUCT_IMAGES
                    WHERE PRODUCT_ID = @ProductId
                    ORDER BY IS_PRIMARY DESC, DISPLAY_ORDER ASC;";

                using var multi = await connection.QueryMultipleAsync(querySql, new { ProductId = productId });
                productMaster.WeightOptions = (await multi.ReadAsync<ProductWeightOptionDto>()).ToList();
                productMaster.Images = (await multi.ReadAsync<ProductImageDto>()).ToList();
            }

            return productMaster;
        }

        public async Task<(List<ProductDto> Items, int TotalRecords)> GetProductsAsync(GetProductsQueryDto query, CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();
            using var multi = await connection.QueryMultipleAsync(
                "dbo.PR_GET_PRODUCTS",
                new
                {
                    USER_TYPE = string.IsNullOrWhiteSpace(query.UserType) ? "GUEST" : query.UserType,
                    USER_ID = query.UserId,
                    PRODUCT_ID = query.ProductId,
                    CATEGORY_ID = query.CategoryId,
                    SEARCH_TERM = query.SearchTerm,
                    IS_FEATURED = query.IsFeatured,
                    IS_BESTSELLER = query.IsBestseller,
                    IS_ACTIVE = query.IsActive,
                    IS_DELETED = query.IsDeleted,
                    IS_WISHLISTED_ONLY = query.IsWishlistedOnly,
                    IS_RECENTLY_ORDERED_ONLY = query.IsRecentlyOrderedOnly,
                    MIN_PRICE = query.MinPrice,
                    MAX_PRICE = query.MaxPrice,
                    SORT_BY = string.IsNullOrWhiteSpace(query.SortBy) ? "DisplayOrder" : query.SortBy,
                    SORT_ORDER = string.IsNullOrWhiteSpace(query.SortOrder) ? "ASC" : query.SortOrder,
                    PAGE_NUMBER = query.PageNumber < 1 ? 1 : query.PageNumber,
                    PAGE_SIZE = query.PageSize < 1 ? 10 : query.PageSize
                },
                commandType: CommandType.StoredProcedure);

            int totalRecords = await multi.ReadFirstOrDefaultAsync<int>();
            var products = (await multi.ReadAsync<ProductDto>()).ToList();
            var weightOptions = (await multi.ReadAsync<ProductWeightOptionDto>()).ToList();
            var images = (await multi.ReadAsync<ProductImageDto>()).ToList();

            var weightOptionLookup = weightOptions.ToLookup(w => w.ProductId);
            var imageLookup = images.ToLookup(img => img.ProductId);

            foreach (var product in products)
            {
                product.WeightOptions = weightOptionLookup[product.ProductId].ToList();
                product.Images = imageLookup[product.ProductId].ToList();
            }

            return (products, totalRecords);
        }
    }
}
