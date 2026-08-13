using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using System;

namespace MeatDelivery.Api.Extensions
{
    public static class CorsExtensions
    {
        public const string PolicyName = "MeatDeliveryCorsPolicy";

        public static IServiceCollection AddCorsPolicy(
            this IServiceCollection services,
            IConfiguration configuration)
        {
            var allowedOrigins =
                configuration
                    .GetSection("CorsSettings:AllowedOrigins")
                    .Get<string[]>()
                ?? Array.Empty<string>();

            services.AddCors(options =>
            {
                options.AddPolicy(PolicyName, policy =>
                {
                    if (allowedOrigins.Length > 0 && !allowedOrigins.Contains("*"))
                    {
                        policy
                            .WithOrigins(allowedOrigins)
                            .AllowAnyHeader()
                            .AllowAnyMethod()
                            .AllowCredentials();
                    }
                    else
                    {
                        policy
                            .AllowAnyOrigin()
                            .AllowAnyHeader()
                            .AllowAnyMethod();
                    }
                });
            });

            return services;
        }

        public static IApplicationBuilder UseCorsPolicy(
            this IApplicationBuilder app)
        {
            return app.UseCors(PolicyName);
        }
    }
}
