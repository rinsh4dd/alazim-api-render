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

            using var multi = await connection.QueryMultipleAsync(
                "dbo.PR_GET_PRODUCT_CUSTOMIZATION_HIERARCHY",
                new { PRODUCT_ID = productId },
                commandType: CommandType.StoredProcedure);

            var product = await multi.ReadFirstOrDefaultAsync<ProductDto>();
            if (product == null)
            {
                return null;
            }

            var template = await multi.ReadFirstOrDefaultAsync<CustomizationTemplateHierarchyDto>();
            var groups = (await multi.ReadAsync<CustomizationGroupHierarchyDto>()).ToList();
            var options = (await multi.ReadAsync<CustomizationOptionHierarchyDto>()).ToList();

            if (template != null)
            {
                var optionsByGroup = options
                    .GroupBy(o => o.CustomizationGroupId)
                    .ToDictionary(g => g.Key, g => g.ToList());

                foreach (var group in groups)
                {
                    if (optionsByGroup.TryGetValue(group.CustomizationGroupId, out var groupOpts))
                    {
                        group.Options = groupOpts;
                    }
                }

                template.Groups = groups.Where(g => g.Options.Count > 0).ToList();
            }

            return new ProductCustomizationHierarchyDto
            {
                ProductId = product.ProductId,
                ProductNameEn = product.ProductNameEn,
                ProductNameAr = product.ProductNameAr,
                IsCustomizable = product.IsCustomizable,
                CustomizationTemplateId = product.CustomizationTemplateId,
                Template = template
            };
        }
    }
}
