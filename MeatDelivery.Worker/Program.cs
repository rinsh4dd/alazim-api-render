using Hangfire;
using Hangfire.MemoryStorage;
using MeatDelivery.Application;
using MeatDelivery.Infrastructure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using System;

var builder = Host.CreateApplicationBuilder(args);

// Register ASP.NET Core Routing
builder.Services.AddRouting();

// Register Application & Infrastructure Services
builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);

// Configure Hangfire Storage & Server Engine
builder.Services.AddHangfire(config => config
    .SetDataCompatibilityLevel(CompatibilityLevel.Version_180)
    .UseSimpleAssemblyNameTypeSerializer()
    .UseRecommendedSerializerSettings()
    .UseMemoryStorage());

// Register Hangfire Background Worker Server
builder.Services.AddHangfireServer(options =>
{
    options.WorkerCount = Environment.ProcessorCount * 2;
    options.ServerName = $"MeatDeliveryWorker_{Environment.MachineName}";
});

var host = builder.Build();

Console.WriteLine("🚀 MeatDelivery Hangfire Background Worker Service Started Successfully!");

host.Run();
