using System.Data;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Dapper;
using MeatDelivery.Application.DTOs.Product;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Product;
using MeatDelivery.Domain.Enums;

namespace MeatDelivery.Infrastructure.Repositories.Catalog
{
    public class ProductRepository : IProductRepository
    {
        private readonly IDapperRepository _dapperRepository;

        public ProductRepository(IDapperRepository dapperRepository)
        {
            _dapperRepository = dapperRepository;
        }

        public async Task<ProductDto?> SaveProductFullAsync(SaveProductDto request, CancellationToken cancellationToken = default)
        {
            // 1. Save Master Product via Stored Procedure
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
                    IS_ACTIVE = request.IsActive
                }
            );

            if (request.Mode == Mode.DELETE || productMaster == null)
            {
                return productMaster;
            }

            long productId = productMaster.ProductId;

            using var connection = _dapperRepository.CreateConnection();
            if (connection.State != ConnectionState.Open)
                connection.Open();

            using var transaction = connection.BeginTransaction();
            try
            {
                // 2. Sync Weight Options & Prices if provided
                if (request.WeightOptions != null)
                {
                    const string deletePricesSql = "DELETE FROM dbo.PRODUCT_PRICES WHERE PRODUCT_ID = @ProductId;";
                    const string deleteWeightOptionsSql = "DELETE FROM dbo.PRODUCT_WEIGHT_OPTIONS WHERE PRODUCT_ID = @ProductId;";

                    await connection.ExecuteAsync(deletePricesSql, new { ProductId = productId }, transaction);
                    await connection.ExecuteAsync(deleteWeightOptionsSql, new { ProductId = productId }, transaction);

                    foreach (var option in request.WeightOptions)
                    {
                        const string insertWeightSql = @"
                            INSERT INTO dbo.PRODUCT_WEIGHT_OPTIONS
                            (PRODUCT_ID, UNIT_ID, UNIT_VALUE, IS_CUSTOM_WEIGHT, MIN_WEIGHT, MAX_WEIGHT,
                             MIN_ORDER_QUANTITY, MAX_ORDER_QUANTITY, QUANTITY_INCREMENT, IS_DEFAULT, DISPLAY_ORDER, IS_ACTIVE, CREATED_AT)
                            VALUES
                            (@ProductId, @UnitId, @UnitValue, @IsCustomWeight, @MinWeight, @MaxWeight,
                             @MinOrderQuantity, @MaxOrderQuantity, @QuantityIncrement, @IsDefault, @DisplayOrder, @IsActive, SYSUTCDATETIME());
                            SELECT CAST(SCOPE_IDENTITY() AS BIGINT);";

                        var weightOptionId = await connection.ExecuteScalarAsync<long>(insertWeightSql, new
                        {
                            ProductId = productId,
                            option.UnitId,
                            option.UnitValue,
                            option.IsCustomWeight,
                            option.MinWeight,
                            option.MaxWeight,
                            option.MinOrderQuantity,
                            option.MaxOrderQuantity,
                            option.QuantityIncrement,
                            option.IsDefault,
                            option.DisplayOrder,
                            option.IsActive
                        }, transaction);

                        const string insertPriceSql = @"
                            INSERT INTO dbo.PRODUCT_PRICES
                            (PRODUCT_ID, PRODUCT_WEIGHT_OPTION_ID, PRICE_TYPE, REGULAR_PRICE, DISCOUNT_PRICE, CURRENCY_CODE, IS_ACTIVE, CREATED_AT)
                            VALUES
                            (@ProductId, @ProductWeightOptionId, @PriceType, @RegularPrice, @DiscountPrice, @CurrencyCode, @IsActive, SYSUTCDATETIME());";

                        await connection.ExecuteAsync(insertPriceSql, new
                        {
                            ProductId = productId,
                            ProductWeightOptionId = weightOptionId,
                            PriceType = string.IsNullOrWhiteSpace(option.PriceType) ? "FIXED" : option.PriceType,
                            option.RegularPrice,
                            option.DiscountPrice,
                            CurrencyCode = string.IsNullOrWhiteSpace(option.CurrencyCode) ? "AED" : option.CurrencyCode,
                            option.IsActive
                        }, transaction);
                    }
                }

                // 3. Sync Product Images if provided
                if (request.Images != null)
                {
                    const string deleteImagesSql = "DELETE FROM dbo.PRODUCT_IMAGES WHERE PRODUCT_ID = @ProductId;";
                    await connection.ExecuteAsync(deleteImagesSql, new { ProductId = productId }, transaction);

                    foreach (var img in request.Images)
                    {
                        const string insertImageSql = @"
                            INSERT INTO dbo.PRODUCT_IMAGES
                            (PRODUCT_ID, IMAGE_URL, IS_PRIMARY, DISPLAY_ORDER, IS_ACTIVE, CREATED_AT)
                            VALUES
                            (@ProductId, @ImageUrl, @IsPrimary, @DisplayOrder, @IsActive, SYSUTCDATETIME());";

                        await connection.ExecuteAsync(insertImageSql, new
                        {
                            ProductId = productId,
                            img.ImageUrl,
                            img.IsPrimary,
                            img.DisplayOrder,
                            img.IsActive
                        }, transaction);
                    }
                }

                transaction.Commit();
            }
            catch
            {
                transaction.Rollback();
                throw;
            }

            // 4. Fetch Full Product Details with WeightOptions, Prices, and Images
            const string sql = @"
                SELECT
                    p.PRODUCT_ID AS ProductId, p.CATEGORY_ID AS CategoryId,
                    c.CATEGORY_NAME_EN AS CategoryNameEn, p.DOC_NO AS DocNo, p.DOC_TYPE AS DocType,
                    p.PRODUCT_NAME_EN AS ProductNameEn, p.PRODUCT_NAME_AR AS ProductNameAr,
                    p.DESCRIPTION_EN AS DescriptionEn, p.DESCRIPTION_AR AS DescriptionAr,
                    p.COUNTRY_OF_ORIGIN AS CountryOfOrigin,
                    p.IS_HALAL_CERTIFIED AS IsHalalCertified, p.HALAL_CERTIFICATE_NO AS HalalCertificateNo,
                    p.HALAL_CERTIFICATE_URL AS HalalCertificateUrl,
                    p.NUTRITION_INFORMATION_EN AS NutritionInformationEn,
                    p.NUTRITION_INFORMATION_AR AS NutritionInformationAr,
                    p.STORAGE_INSTRUCTIONS_EN AS StorageInstructionsEn,
                    p.STORAGE_INSTRUCTIONS_AR AS StorageInstructionsAr,
                    p.IS_CUSTOMIZABLE AS IsCustomizable, p.CUSTOMIZATION_TEMPLATE_ID AS CustomizationTemplateId,
                    p.DISPLAY_ORDER AS DisplayOrder, p.IS_FEATURED AS IsFeatured,
                    p.IS_BESTSELLER AS IsBestseller, p.IS_ACTIVE AS IsActive,
                    p.CREATED_AT AS CreatedAt, p.UPDATED_AT AS UpdatedAt
                FROM dbo.PRODUCTS p
                LEFT JOIN dbo.CATEGORIES c ON p.CATEGORY_ID = c.CATEGORY_ID
                WHERE p.PRODUCT_ID = @ProductId;

                SELECT
                    w.PRODUCT_WEIGHT_OPTION_ID AS ProductWeightOptionId,
                    w.PRODUCT_ID AS ProductId, w.UNIT_ID AS UnitId,
                    u.UNIT AS Unit, u.UNIT_DESCRIPTION AS UnitDescription,
                    w.UNIT_VALUE AS UnitValue, w.IS_CUSTOM_WEIGHT AS IsCustomWeight,
                    w.MIN_WEIGHT AS MinWeight, w.MAX_WEIGHT AS MaxWeight,
                    w.MIN_ORDER_QUANTITY AS MinOrderQuantity, w.MAX_ORDER_QUANTITY AS MaxOrderQuantity,
                    w.QUANTITY_INCREMENT AS QuantityIncrement, w.IS_DEFAULT AS IsDefault,
                    w.DISPLAY_ORDER AS DisplayOrder, w.IS_ACTIVE AS IsActive,
                    pr.PRODUCT_PRICE_ID AS ProductPriceId, pr.PRICE_TYPE AS PriceType,
                    pr.REGULAR_PRICE AS RegularPrice, pr.DISCOUNT_PRICE AS DiscountPrice,
                    pr.CURRENCY_CODE AS CurrencyCode
                FROM dbo.PRODUCT_WEIGHT_OPTIONS w
                INNER JOIN dbo.MEASUREMENT_UNITS u ON w.UNIT_ID = u.UNIT_ID
                LEFT JOIN dbo.PRODUCT_PRICES pr ON w.PRODUCT_WEIGHT_OPTION_ID = pr.PRODUCT_WEIGHT_OPTION_ID
                WHERE w.PRODUCT_ID = @ProductId
                ORDER BY w.DISPLAY_ORDER ASC, w.PRODUCT_WEIGHT_OPTION_ID ASC;

                SELECT
                    PRODUCT_IMAGE_ID AS ProductImageId, PRODUCT_ID AS ProductId,
                    IMAGE_URL AS ImageUrl, IS_PRIMARY AS IsPrimary,
                    DISPLAY_ORDER AS DisplayOrder, IS_ACTIVE AS IsActive
                FROM dbo.PRODUCT_IMAGES
                WHERE PRODUCT_ID = @ProductId
                ORDER BY IS_PRIMARY DESC, DISPLAY_ORDER ASC;";

            using var getConn = _dapperRepository.CreateConnection();
            using var multi = await getConn.QueryMultipleAsync(sql, new { ProductId = productId });

            var fullProduct = await multi.ReadFirstOrDefaultAsync<ProductDto>();
            if (fullProduct != null)
            {
                fullProduct.WeightOptions = (await multi.ReadAsync<ProductWeightOptionDto>()).ToList();
                fullProduct.Images = (await multi.ReadAsync<ProductImageDto>()).ToList();
            }

            return fullProduct;
        }
    }
}
