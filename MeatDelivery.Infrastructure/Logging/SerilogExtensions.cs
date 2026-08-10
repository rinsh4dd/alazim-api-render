using Microsoft.Extensions.Configuration;
using Serilog;
using Serilog.Events;

namespace MeatDelivery.Infrastructure.Logging
{
    public static class SerilogExtensions
    {
        public static LoggerConfiguration ConfigureSerilog(
            this LoggerConfiguration loggerConfiguration,
            IConfiguration configuration)
        {
            return loggerConfiguration
                .ReadFrom.Configuration(configuration)
                .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
                .MinimumLevel.Override("Microsoft.AspNetCore", LogEventLevel.Warning)
                .Enrich.FromLogContext()
                .Enrich.WithMachineName()
                .Enrich.WithThreadId()
                .Enrich.WithEnvironmentName();
        }
    }
}
