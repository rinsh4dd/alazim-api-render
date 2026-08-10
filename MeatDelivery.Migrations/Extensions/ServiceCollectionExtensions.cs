using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using MeatDelivery.Migrations.Configuration;
using MeatDelivery.Migrations.Runners;
using MeatDelivery.Migrations.Services;

namespace MeatDelivery.Migrations.Extensions
{
    public static class ServiceCollectionExtensions
    {
        public static IServiceCollection AddMigrationServices(
            this IServiceCollection services,
            IConfiguration configuration)
        {
            // Bind settings
            services.Configure<DatabaseSettings>(
                configuration.GetSection("DatabaseSettings"));

            // Sql Script Executor & Runner
            services.AddScoped<ISqlScriptExecutor, SqlScriptExecutor>();
            services.AddScoped<DatabaseMigrationRunner>();

            // Migration orchestrator
            services.AddScoped<IMigrationOrchestrator, MigrationOrchestrator>();

            return services;
        }
    }
}
