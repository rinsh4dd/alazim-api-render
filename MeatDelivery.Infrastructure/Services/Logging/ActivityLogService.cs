using MeatDelivery.Application.Interfaces.Logging;
using MeatDelivery.Application.Interfaces;
using Dapper;

namespace MeatDelivery.Infrastructure.Services.Logging
{
    public sealed class ActivityLogService : IActivityLogService
    {
        private readonly IDbConnectionFactory _connectionFactory;

        public ActivityLogService(IDbConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task LogActivityAsync(
            Guid? userId,
            string activityType,
            string description,
            string? source = null,
            string? referenceId = null,
            CancellationToken cancellationToken = default)
        {
            using var connection = _connectionFactory.CreateConnection();

            await connection.ExecuteAsync(
                "usp_Logs_InsertActivityLog",
                new
                {
                    UserId = userId,
                    ActivityType = activityType,
                    Description = description,
                    Source = source,
                    ReferenceId = referenceId
                });
        }
    }
}
