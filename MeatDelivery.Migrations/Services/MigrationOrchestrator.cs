using Microsoft.Extensions.Logging;
using MeatDelivery.Migrations.Runners;

namespace MeatDelivery.Migrations.Services
{
    public sealed class MigrationOrchestrator : IMigrationOrchestrator
    {
        private readonly DatabaseMigrationRunner _runner;
        private readonly ILogger<MigrationOrchestrator> _logger;

        public MigrationOrchestrator(
            DatabaseMigrationRunner runner,
            ILogger<MigrationOrchestrator> logger)
        {
            _runner = runner;
            _logger = logger;
        }

        public async Task RunAsync()
        {
            _logger.LogInformation("Starting database migration...");

            using var cts = new CancellationTokenSource();

            Console.CancelKeyPress += (_, e) =>
            {
                e.Cancel = true;
                cts.Cancel();
            };

            await _runner.RunAsync(cts.Token);
            _logger.LogInformation("Migration completed successfully.");
        }
    }
}
