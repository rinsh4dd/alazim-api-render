using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Serilog;
using MeatDelivery.Migrations.Extensions;
using MeatDelivery.Migrations.Services;

var builder = Host.CreateApplicationBuilder(args);

Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .WriteTo.Console()
    .WriteTo.File("logs/migrations-.log", rollingInterval: RollingInterval.Day)
    .CreateLogger();

builder.Services.AddSerilog();
builder.Services.AddMigrationServices(builder.Configuration);

using var host = builder.Build();

var orchestrator = host.Services.GetRequiredService<IMigrationOrchestrator>();
await orchestrator.RunAsync();