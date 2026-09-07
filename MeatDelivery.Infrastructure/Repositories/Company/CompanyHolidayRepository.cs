using System.Collections.Generic;
using System.Data;
using System.Threading;
using System.Threading.Tasks;
using Dapper;
using MeatDelivery.Application.DTOs.Company;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Company;

namespace MeatDelivery.Infrastructure.Repositories.Company
{
    public class CompanyHolidayRepository : ICompanyHolidayRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public CompanyHolidayRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<List<CompanyHolidayDto>> GetCompanyHolidaysAsync(GetCompanyHolidaysQueryDto query, CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();

            var parameters = new DynamicParameters();
            parameters.Add("COMPANY_HOLIDAY_ID", query?.CompanyHolidayId);

            var commandDef = new CommandDefinition(
                "dbo.PR_GET_COMPANY_HOLIDAYS",
                parameters,
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken
            );

            var result = await connection.QueryAsync<CompanyHolidayDto>(commandDef);
            return result.AsList();
        }

        public async Task<long> SaveCompanyHolidayAsync(SaveCompanyHolidayDto request, CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();

            var parameters = new DynamicParameters();
            parameters.Add("MODE", request.Mode.ToString());
            parameters.Add("COMPANY_HOLIDAY_ID", request.CompanyHolidayId);
            parameters.Add("HOLIDAY_DATE", request.HolidayDate);
            parameters.Add("HOLIDAY_TYPE", request.HolidayType);
            parameters.Add("IS_FULL_DAY", request.IsFullDay);
            parameters.Add("START_TIME", request.StartTime);
            parameters.Add("END_TIME", request.EndTime);
            parameters.Add("REASON_EN", request.ReasonEn);
            parameters.Add("REASON_AR", request.ReasonAr);
            parameters.Add("IS_ACTIVE", request.IsActive);

            var commandDef = new CommandDefinition(
                "dbo.PR_SAVE_COMPANY_HOLIDAY",
                parameters,
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken
            );

            return await connection.ExecuteScalarAsync<long>(commandDef);
        }
    }
}
