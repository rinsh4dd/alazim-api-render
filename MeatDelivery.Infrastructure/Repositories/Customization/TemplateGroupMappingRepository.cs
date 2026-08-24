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
    public class TemplateGroupMappingRepository : ITemplateGroupMappingRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public TemplateGroupMappingRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<List<TemplateGroupMappingDto>> SaveTemplateGroupMappingAsync(
            SaveTemplateGroupMappingDto dto,
            CancellationToken cancellationToken = default)
        {
            var table = new DataTable();
            table.Columns.Add("GROUP_ID", typeof(long));

            if (dto.GroupIds != null && dto.GroupIds.Count > 0)
            {
                foreach (var groupId in dto.GroupIds.Distinct())
                {
                    if (groupId > 0)
                    {
                        table.Rows.Add(groupId);
                    }
                }
            }

            using var connection = _connectionFactory.CreateConnection();
            var result = await connection.QueryAsync<TemplateGroupMappingDto>(
                "dbo.PR_SAVE_TEMPLATE_GROUP_MAPPING",
                new
                {
                    MODE = dto.Mode.ToString(),
                    TEMPLATE_GROUP_MAPPING_ID = dto.TemplateGroupMappingId,
                    CUSTOMIZATION_TEMPLATE_ID = dto.CustomizationTemplateId,
                    CUSTOMIZATION_GROUP_ID = dto.CustomizationGroupId,
                    GROUP_IDS = table.AsTableValuedParameter("dbo.TT_CUSTOMIZATION_GROUP_IDS"),
                    IS_ACTIVE = dto.IsActive
                },
                commandType: CommandType.StoredProcedure);

            return result.ToList();
        }

        public async Task<(List<TemplateGroupMappingDto> Items, int TotalRecords)> GetTemplateGroupMappingsAsync(
            GetTemplateGroupMappingsQueryDto query,
            CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();
            using var multi = await connection.QueryMultipleAsync(
                "dbo.PR_GET_TEMPLATE_GROUP_MAPPINGS",
                new
                {
                    PAGE_NUMBER = query.PageNumber,
                    PAGE_SIZE = query.PageSize,
                    CUSTOMIZATION_TEMPLATE_ID = query.CustomizationTemplateId,
                    CUSTOMIZATION_GROUP_ID = query.CustomizationGroupId,
                    IS_ACTIVE = query.IsActive
                },
                commandType: CommandType.StoredProcedure);

            int totalRecords = await multi.ReadSingleAsync<int>();
            var items = (await multi.ReadAsync<TemplateGroupMappingDto>()).ToList();

            return (items, totalRecords);
        }
    }
}
