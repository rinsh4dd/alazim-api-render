using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Dapper;
using MeatDelivery.Application.DTOs.Customization;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Customization;

namespace MeatDelivery.Infrastructure.Repositories.Customization
{
    public class CustomizationGroupRepository : ICustomizationGroupRepository
    {
        private readonly IDapperRepository _dapperRepository;
        private readonly IDbConnectionFactory _connectionFactory;

        public CustomizationGroupRepository(
            IDapperRepository dapperRepository,
            IDbConnectionFactory connectionFactory)
        {
            _dapperRepository = dapperRepository;
            _connectionFactory = connectionFactory;
        }

        public async Task<CustomizationGroupDto?> SaveCustomizationGroupAsync(
            SaveCustomizationGroupDto request,
            CancellationToken cancellationToken = default)
        {
            return await _dapperRepository.QueryFirstOrDefaultAsync<CustomizationGroupDto>(
                "PR_SAVE_CUSTOMIZATION_GROUP",
                new
                {
                    MODE = request.Mode.ToString(),
                    CUSTOMIZATION_GROUP_ID = request.CustomizationGroupId,
                    GROUP_CODE = request.GroupCode,
                    GROUP_NAME_EN = request.GroupNameEn,
                    GROUP_NAME_AR = request.GroupNameAr,
                    IS_ADDITIONAL_PRICE_AVAILABLE = request.IsAdditionalPriceAvailable,
                    PRICING_TYPE = request.PricingType.ToString(),
                    IS_CUSTOM_DATA_ALLOWED = request.IsCustomDataAllowed,
                    IS_ACTIVE = request.IsActive
                }
            );
        }

        public async Task<(List<CustomizationGroupDto> Items, int TotalRecords)> GetCustomizationGroupsAsync(
            GetCustomizationGroupsQueryDto query,
            CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();
            using var multi = await connection.QueryMultipleAsync(
                "dbo.PR_GET_CUSTOMIZATION_GROUPS",
                new
                {
                    PAGE_NUMBER = query.PageNumber,
                    PAGE_SIZE = query.PageSize,
                    SEARCH = query.Search,
                    CUSTOMIZATION_GROUP_ID = query.CustomizationGroupId,
                    IS_ACTIVE = query.IsActive
                },
                commandType: CommandType.StoredProcedure);

            int totalRecords = await multi.ReadSingleAsync<int>();
            var items = (await multi.ReadAsync<CustomizationGroupDto>()).ToList();

            if (query.CustomizationGroupId.HasValue && items.Count > 0 && !multi.IsConsumed)
            {
                var options = (await multi.ReadAsync<CustomizationOptionDto>()).ToList();
                items[0].Options = options;
            }

            return (items, totalRecords);
        }
    }
}
