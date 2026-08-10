using Hangfire;
using Hangfire.Dashboard;
using Hangfire.MemoryStorage;
using Hangfire.SqlServer;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using System;

namespace MeatDelivery.Api.Extensions
{
    public static class HangfireExtensions
    {
        public static IServiceCollection AddHangfireSupport(this IServiceCollection services, IConfiguration configuration)
        {
            var connectionString = configuration.GetConnectionString("DefaultConnection");

            services.AddHangfire(config =>
            {
                config.SetDataCompatibilityLevel(CompatibilityLevel.Version_180)
                      .UseSimpleAssemblyNameTypeSerializer()
                      .UseRecommendedSerializerSettings();

                // Use In-Memory storage for seamless local development testing without SQL Server requirement
                config.UseMemoryStorage();
            });

            return services;
        }

        public static IApplicationBuilder UseHangfireSupport(this IApplicationBuilder app)
        {
            app.UseHangfireDashboard("/hangfire", new DashboardOptions
            {
                DashboardTitle = "MeatDelivery Background Jobs Dashboard",
                Authorization = new[] { new HangfireCustomDashboardAuthorizationFilter() }
            });

            return app;
        }
    }

    public class HangfireCustomDashboardAuthorizationFilter : IDashboardAuthorizationFilter
    {
        public bool Authorize(DashboardContext context)
        {
            var httpContext = context.GetHttpContext();
            var env = httpContext.RequestServices.GetRequiredService<IHostEnvironment>();
            
            if (env.IsDevelopment())
            {
                return true;
            }

            return httpContext.User.Identity?.IsAuthenticated == true && httpContext.User.IsInRole("Admin");
        }
    }
}
