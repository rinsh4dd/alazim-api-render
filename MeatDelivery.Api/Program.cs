using System.IO;
using System.Text.Json.Serialization;
using Microsoft.Extensions.FileProviders;
using Microsoft.OpenApi;
using Scalar.AspNetCore;
using Serilog;
using MeatDelivery.Api.Extensions;
using MeatDelivery.Api.Filters;
using MeatDelivery.Application;
using MeatDelivery.Infrastructure;
using MeatDelivery.Infrastructure.Logging;

Environment.SetEnvironmentVariable("DOTNET_USE_POLLING_FILE_WATCHER", "true");
Environment.SetEnvironmentVariable("DOTNET_hostBuilder__reloadConfigOnChange", "false");

var builder = WebApplication.CreateBuilder(args);

builder.Host.UseSerilog((context, services, configuration) =>
    configuration.ConfigureSerilog(context.Configuration));

builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddHangfireSupport(builder.Configuration);
builder.Services.AddCorsPolicy(builder.Configuration);
builder.Services.AddRateLimitPolicy(builder.Configuration);
builder.Services.AddApiVersioningSupport();
builder.Services.AddGzipCompressionSupport();

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")
    ?? builder.Configuration.GetConnectionString("MasterDb")
    ?? throw new InvalidOperationException("DefaultConnection connection string missing.");

builder.Services.AddHealthChecks()
    .AddSqlServer(
        connectionString: connectionString,
        name: "SQL Server (DefaultConnection)",
        tags: new[] { "db", "sql", "sqlserver" });

builder.Services.AddControllers(options =>
{
    options.Filters.Add<ValidationFilter>();
})
.AddJsonOptions(options =>
{
    options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
});

builder.Services.AddOpenApi();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "MeatDelivery Client API",
        Version = "v1",
        Description = "REST API for MeatDelivery Client Application",
        Contact = new OpenApiContact
        {
            Name = "MeatDelivery Development Team",
            Email = "support@meatdelivery.com"
        }
    });

    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter JWT token in the format: Bearer {your-token}"
    });

    options.AddSecurityRequirement(document => new OpenApiSecurityRequirement
    {
        [new OpenApiSecuritySchemeReference("Bearer", document)] = []
    });
});

var app = builder.Build();

app.MapOpenApi();
app.UseSwagger();
app.UseSwaggerUI(options =>
{
    options.SwaggerEndpoint("/swagger/v1/swagger.json", "MeatDelivery Client API v1");
    options.RoutePrefix = "swagger";
    options.DocumentTitle = "MeatDelivery Client API Documentation";
});

app.MapScalarApiReference(options =>
{
    options.WithTitle("MeatDelivery Client API Reference")
           .WithTheme(ScalarTheme.Purple)
           .WithOpenApiRoutePattern("/swagger/v1/swagger.json")
           .WithDefaultHttpClient(ScalarTarget.Http, ScalarClient.Http11);
});

app.UseGzipCompressionSupport();

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

var uploadsPath = Path.Combine(builder.Environment.ContentRootPath, "Uploads");
if (!Directory.Exists(uploadsPath))
{
    Directory.CreateDirectory(uploadsPath);
}

app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(uploadsPath),
    RequestPath = "/Uploads"
});

app.UseRouting();
app.UseCorsPolicy();
app.UseAuthentication();
app.UseRateLimitPolicy();
app.UseCustomMiddleware();
app.UseAuthorization();
app.UseHangfireSupport();

app.MapControllers();
app.MapHealthChecks("/api/health");

Log.Information("🚀 Al Azima Meat Delivery API started successfully! Listening on configured ports. Swagger UI: /swagger");

app.Run();