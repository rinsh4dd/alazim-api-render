using Microsoft.Extensions.FileProviders;
using Microsoft.OpenApi;
using Serilog;
using MeatDelivery.Api.Extensions;
using MeatDelivery.Api.Filters;
using MeatDelivery.Application;
using MeatDelivery.Infrastructure;
using MeatDelivery.Infrastructure.Logging;
using System.IO;

// Prevent Linux inotify instance exhaustion in container environments (Render/Docker)
Environment.SetEnvironmentVariable("DOTNET_USE_POLLING_FILE_WATCHER", "true");
Environment.SetEnvironmentVariable("DOTNET_hostBuilder__reloadConfigOnChange", "false");

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog
builder.Host.UseSerilog((context, services, configuration) =>
    configuration.ConfigureSerilog(context.Configuration));

// -----------------------------------------------------------------------------
// Service Registration
// -----------------------------------------------------------------------------

// Register Application layer services (Validators & Behaviors)
builder.Services.AddApplication();

// Register application infrastructure services
builder.Services.AddInfrastructure(builder.Configuration);

// Configure Background Job Infrastructure (BE-015)
builder.Services.AddHangfireSupport(builder.Configuration);

// Configure CORS Policy (BE-017)
builder.Services.AddCorsPolicy(builder.Configuration);

// Configure Rate Limiting Policy (BE-019)
builder.Services.AddRateLimitPolicy(builder.Configuration);

// Configure API Versioning (BE-008)
builder.Services.AddApiVersioningSupport();

// Configure Gzip Response Compression
builder.Services.AddGzipCompressionSupport();

// Add Application Health Checks
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") 
    ?? builder.Configuration.GetConnectionString("MasterDb") 
    ?? throw new InvalidOperationException("DefaultConnection connection string missing.");

builder.Services.AddHealthChecks()
    .AddSqlServer(
        connectionString: connectionString,
        name: "SQL Server (DefaultConnection)",
        tags: new[] { "db", "sql", "sqlserver" });

// Register MVC controllers with automatic FluentValidation filter (BE-012)
builder.Services.AddControllers(options =>
{
    options.Filters.Add<ValidationFilter>();
});

// Register OpenAPI endpoint generation
builder.Services.AddOpenApi();

// Register Swagger/OpenAPI documentation generator
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

// -----------------------------------------------------------------------------
// Middleware Pipeline Configuration
// -----------------------------------------------------------------------------

app.MapOpenApi();
app.UseSwagger();
app.UseSwaggerUI(options =>
{
    options.SwaggerEndpoint("/swagger/v1/swagger.json", "MeatDelivery Client API v1");
    options.RoutePrefix = "swagger";
    options.DocumentTitle = "MeatDelivery Client API Documentation";
});

app.UseGzipCompressionSupport();

app.UseHttpsRedirection();

// Configure static file serving for uploaded product images & assets (BE-014)
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

// Enable Hangfire Dashboard at /hangfire
app.UseHangfireSupport();

app.MapControllers();

app.MapHealthChecks("/api/health");

Log.Information("🚀 Al Azeem Meat Delivery API started successfully! Listening on configured ports. Swagger UI: /swagger");

app.Run();