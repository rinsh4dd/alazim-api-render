using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Dapper;
using MeatDelivery.Application.DTOs.Customization;
using MeatDelivery.Application.DTOs.Product;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Customization;

namespace MeatDelivery.Infrastructure.Repositories.Customization
{
    public class CustomizationTemplateRepository : ICustomizationTemplateRepository
    {
        private readonly IDapperRepository _dapperRepository;
        private readonly IDbConnectionFactory _connectionFactory;

        public CustomizationTemplateRepository(
            IDapperRepository dapperRepository,
            IDbConnectionFactory connectionFactory)
        {
            _dapperRepository = dapperRepository;
            _connectionFactory = connectionFactory;
        }

        public async Task<CustomizationTemplateDto?> SaveCustomizationTemplateAsync(
            SaveCustomizationTemplateDto request,
            CancellationToken cancellationToken = default)
        {
            return await _dapperRepository.QueryFirstOrDefaultAsync<CustomizationTemplateDto>(
                "PR_SAVE_CUSTOMIZATION_TEMPLATE",
                new
                {
                    MODE = request.Mode.ToString(),
                    CUSTOMIZATION_TEMPLATE_ID = request.CustomizationTemplateId,
                    TEMPLATE_NAME_EN = request.TemplateNameEn,
                    TEMPLATE_NAME_AR = request.TemplateNameAr,
                    DESCRIPTION_EN = request.DescriptionEn,
                    DESCRIPTION_AR = request.DescriptionAr,
                    IS_ACTIVE = request.IsActive
                }
            );
        }

        public async Task<(List<CustomizationTemplateDto> Items, int TotalRecords)> GetCustomizationTemplatesAsync(
            GetCustomizationTemplatesQueryDto query,
            CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();
            using var multi = await connection.QueryMultipleAsync(
                "dbo.PR_GET_CUSTOMIZATION_TEMPLATES",
                new
                {
                    PAGE_NUMBER = query.PageNumber,
                    PAGE_SIZE = query.PageSize,
                    SEARCH = query.Search,
                    CUSTOMIZATION_TEMPLATE_ID = query.CustomizationTemplateId,
                    IS_ACTIVE = query.IsActive
                },
                commandType: CommandType.StoredProcedure);

            int totalRecords = await multi.ReadSingleAsync<int>();
            var items = (await multi.ReadAsync<CustomizationTemplateDto>()).ToList();

            return (items, totalRecords);
        }

        public async Task<ProductCustomizationHierarchyDto?> GetProductCustomizationHierarchyAsync(
            long productId,
            CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();

            const string sql = @"
                SELECT 
                    PRODUCT_ID AS ProductId,
                    PRODUCT_NAME_EN AS ProductNameEn,
                    PRODUCT_NAME_AR AS ProductNameAr,
                    IS_CUSTOMIZABLE AS IsCustomizable,
                    CUSTOMIZATION_TEMPLATE_ID AS CustomizationTemplateId
                FROM dbo.PRODUCTS
                WHERE PRODUCT_ID = @productId;";

            var product = await connection.QueryFirstOrDefaultAsync<ProductDto>(sql, new { productId });

            if (product == null)
            {
                return null;
            }

            var result = new ProductCustomizationHierarchyDto
            {
                ProductId = product.ProductId,
                ProductNameEn = product.ProductNameEn,
                ProductNameAr = product.ProductNameAr,
                IsCustomizable = product.IsCustomizable,
                CustomizationTemplateId = product.CustomizationTemplateId
            };

            if (product.IsCustomizable && product.CustomizationTemplateId.HasValue && product.CustomizationTemplateId.Value > 0)
            {
                result.Template = await GetTemplateCustomizationHierarchyInternalAsync(connection, product.CustomizationTemplateId.Value, cancellationToken);
            }

            return result;
        }

        private static async Task<CustomizationTemplateHierarchyDto?> GetTemplateCustomizationHierarchyInternalAsync(
            IDbConnection connection,
            long templateId,
            CancellationToken cancellationToken)
        {
            // 1. Get Template Details
            using var templateMulti = await connection.QueryMultipleAsync(
                "dbo.PR_GET_CUSTOMIZATION_TEMPLATES",
                new
                {
                    PAGE_NUMBER = 1,
                    PAGE_SIZE = 1,
                    CUSTOMIZATION_TEMPLATE_ID = templateId,
                    IS_ACTIVE = true
                },
                commandType: CommandType.StoredProcedure);

            _ = await templateMulti.ReadSingleAsync<int>();
            var templates = (await templateMulti.ReadAsync<CustomizationTemplateDto>()).ToList();
            var template = templates.FirstOrDefault();

            if (template == null)
            {
                return null;
            }

            var hierarchy = new CustomizationTemplateHierarchyDto
            {
                CustomizationTemplateId = template.CustomizationTemplateId,
                DocNo = template.DocNo,
                TemplateNameEn = template.TemplateNameEn,
                TemplateNameAr = template.TemplateNameAr,
                DescriptionEn = template.DescriptionEn,
                DescriptionAr = template.DescriptionAr,
                IsActive = template.IsActive,
                Groups = new List<CustomizationGroupHierarchyDto>()
            };

            // 2. Get Template Group Mappings
            using var mappingMulti = await connection.QueryMultipleAsync(
                "dbo.PR_GET_TEMPLATE_GROUP_MAPPINGS",
                new
                {
                    PAGE_NUMBER = 1,
                    PAGE_SIZE = 100,
                    CUSTOMIZATION_TEMPLATE_ID = templateId,
                    IS_ACTIVE = true
                },
                commandType: CommandType.StoredProcedure);

            _ = await mappingMulti.ReadSingleAsync<int>();
            var groupMappings = (await mappingMulti.ReadAsync<TemplateGroupMappingDto>()).ToList();

            // 3. For each Group, get Options
            foreach (var mapping in groupMappings)
            {
                var groupDto = new CustomizationGroupHierarchyDto
                {
                    CustomizationGroupId = mapping.CustomizationGroupId,
                    GroupCode = mapping.GroupCode,
                    GroupNameEn = mapping.GroupNameEn,
                    GroupNameAr = mapping.GroupNameAr,
                    IsAdditionalPriceAvailable = mapping.IsAdditionalPriceAvailable,
                    IsActive = mapping.IsActive,
                    Options = new List<CustomizationOptionHierarchyDto>()
                };

                using var optionMulti = await connection.QueryMultipleAsync(
                    "dbo.PR_GET_CUSTOMIZATION_OPTIONS",
                    new
                    {
                        PAGE_NUMBER = 1,
                        PAGE_SIZE = 100,
                        CUSTOMIZATION_GROUP_ID = mapping.CustomizationGroupId,
                        IS_ACTIVE = true
                    },
                    commandType: CommandType.StoredProcedure);

                _ = await optionMulti.ReadSingleAsync<int>();
                var options = (await optionMulti.ReadAsync<CustomizationOptionDto>()).ToList();

                foreach (var opt in options)
                {
                    groupDto.Options.Add(new CustomizationOptionHierarchyDto
                    {
                        CustomizationOptionId = opt.CustomizationOptionId,
                        CustomizationGroupId = opt.CustomizationGroupId,
                        OptionCode = opt.OptionCode,
                        OptionNameEn = opt.OptionNameEn,
                        OptionNameAr = opt.OptionNameAr,
                        AdditionalPrice = opt.AdditionalPrice,
                        IsActive = opt.IsActive
                    });
                }

                hierarchy.Groups.Add(groupDto);
            }

            return hierarchy;
        }
    }
}
