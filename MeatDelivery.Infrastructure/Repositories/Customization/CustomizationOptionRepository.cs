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
    public class CustomizationOptionRepository : ICustomizationOptionRepository
    {
        private readonly IDapperRepository _dapperRepository;
        private readonly IDbConnectionFactory _connectionFactory;

        public CustomizationOptionRepository(
            IDapperRepository dapperRepository,
            IDbConnectionFactory connectionFactory)
        {
            _dapperRepository = dapperRepository;
            _connectionFactory = connectionFactory;
        }

        public async Task<CustomizationOptionDto?> SaveCustomizationOptionAsync(
            SaveCustomizationOptionDto dto,
            CancellationToken cancellationToken = default)
        {
            return await _dapperRepository.QueryFirstOrDefaultAsync<CustomizationOptionDto>(
                "PR_SAVE_CUSTOMIZATION_OPTION",
                new
                {
                    MODE = dto.Mode.ToString(),
                    CUSTOMIZATION_OPTION_ID = dto.CustomizationOptionId,
                    CUSTOMIZATION_GROUP_ID = dto.CustomizationGroupId,
                    OPTION_CODE = dto.OptionCode,
                    OPTION_NAME_EN = dto.OptionNameEn,
                    OPTION_NAME_AR = dto.OptionNameAr,
                    ADDITIONAL_PRICE = dto.AdditionalPrice,
                    IS_ACTIVE = dto.IsActive
                }
            );
        }

        public async Task<(List<CustomizationOptionDto> Items, int TotalRecords)> GetCustomizationOptionsAsync(
            GetCustomizationOptionsQueryDto query,
            CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();
            using var multi = await connection.QueryMultipleAsync(
                "dbo.PR_GET_CUSTOMIZATION_OPTIONS",
                new
                {
                    PAGE_NUMBER = query.PageNumber,
                    PAGE_SIZE = query.PageSize,
                    SEARCH = query.Search,
                    CUSTOMIZATION_GROUP_ID = query.CustomizationGroupId,
                    CUSTOMIZATION_OPTION_ID = query.CustomizationOptionId,
                    IS_ACTIVE = query.IsActive
                },
                commandType: CommandType.StoredProcedure);

            int totalRecords = await multi.ReadSingleAsync<int>();
            var items = (await multi.ReadAsync<CustomizationOptionDto>()).ToList();

            return (items, totalRecords);
        }
    }
}
