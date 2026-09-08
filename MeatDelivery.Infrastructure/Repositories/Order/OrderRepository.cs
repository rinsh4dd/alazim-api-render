using System;
using System.Data;
using System.Threading;
using System.Threading.Tasks;
using Dapper;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Order;

namespace MeatDelivery.Infrastructure.Repositories.Order
{
    public class OrderRepository : IOrderRepository
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public OrderRepository(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<(long OrderId, string DocNo)> PlaceOrderAsync(
            long customerUserId,
            long addressId,
            DateOnly deliveryDate,
            TimeSpan deliverySlotStartTime,
            TimeSpan deliverySlotEndTime,
            string paymentMethod,
            string? deliveryInstructions,
            CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();

            var parameters = new DynamicParameters();
            parameters.Add("CUSTOMER_USER_ID", customerUserId);
            parameters.Add("ADDRESS_ID", addressId);
            parameters.Add("DELIVERY_DATE", deliveryDate.ToDateTime(TimeOnly.MinValue));
            parameters.Add("DELIVERY_SLOT_START_TIME", deliverySlotStartTime);
            parameters.Add("DELIVERY_SLOT_END_TIME", deliverySlotEndTime);
            parameters.Add("PAYMENT_METHOD", paymentMethod);
            parameters.Add("DELIVERY_INSTRUCTIONS", deliveryInstructions);
            parameters.Add("ORDER_ID", dbType: DbType.Int64, direction: ParameterDirection.Output);
            parameters.Add("DOC_NO", dbType: DbType.String, direction: ParameterDirection.Output, size: 50);

            var commandDef = new CommandDefinition(
                "dbo.PR_PLACE_ORDER",
                parameters,
                commandType: CommandType.StoredProcedure,
                cancellationToken: cancellationToken
            );

            await connection.ExecuteAsync(commandDef);

            long orderId = parameters.Get<long>("ORDER_ID");
            string docNo = parameters.Get<string>("DOC_NO");

            return (orderId, docNo);
        }
    }
}
