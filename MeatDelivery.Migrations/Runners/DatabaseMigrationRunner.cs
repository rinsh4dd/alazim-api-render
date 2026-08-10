using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MeatDelivery.Migrations.Configuration;
using MeatDelivery.Migrations.Services;
using System.Reflection;

namespace MeatDelivery.Migrations.Runners
{
    public sealed class DatabaseMigrationRunner
    {
        private readonly ISqlScriptExecutor _sqlScriptExecutor;
        private readonly DatabaseSettings _settings;
        private readonly ILogger<DatabaseMigrationRunner> _logger;

        public DatabaseMigrationRunner(
            ISqlScriptExecutor sqlScriptExecutor,
            IOptions<DatabaseSettings> settings,
            ILogger<DatabaseMigrationRunner> logger)
        {
            _sqlScriptExecutor = sqlScriptExecutor;
            _settings = settings.Value;
            _logger = logger;
        }

        public async Task RunAsync(CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("Starting database migration execution...");
            var connectionString = _settings.ConnectionString;

            await _sqlScriptExecutor.ExecuteScriptsAsync(
                connectionString,
                "MeatDelivery.Migrations.SqlScripts.",
                Assembly.GetExecutingAssembly(),
                cancellationToken);

            _logger.LogInformation("Database migrations completed successfully.");
        }
    }
}
