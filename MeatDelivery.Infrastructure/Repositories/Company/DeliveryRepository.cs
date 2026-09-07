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
    public class DeliveryRepository : IDeliveryRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public DeliveryRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<List<AvailableDeliveryDateDto>> GetAvailableDeliveryDatesAsync(CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();

            var commandDef = new CommandDefinition(
                "dbo.PR_GET_AVAILABLE_DELIVERY_DATES",
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken
            );

            var result = await connection.QueryAsync<AvailableDeliveryDateDto>(commandDef);
            return result.AsList();
        }

        public async Task<List<DeliverySlotDto>> GetAvailableSlotsAsync(DateTime? targetDate = null, CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();

            var parameters = new DynamicParameters();
            parameters.Add("TARGET_DATE", targetDate?.Date);

            var commandDef = new CommandDefinition(
                "dbo.PR_GET_AVAILABLE_DELIVERY_SLOTS",
                parameters,
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken
            );

            var result = await connection.QueryAsync<DeliverySlotDto>(commandDef);
            return result.AsList();
        }
    }
}
