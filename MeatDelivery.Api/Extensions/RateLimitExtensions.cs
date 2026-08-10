using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Threading.RateLimiting;

namespace MeatDelivery.Api.Extensions
{
    public static class RateLimitExtensions
    {
        public const string AuthPolicy = "AuthPolicy";
        public const string OtpPolicy = "OtpPolicy";
        public const string OrderPolicy = "OrderPolicy";

        public static IServiceCollection AddRateLimitPolicy(
            this IServiceCollection services,
            IConfiguration configuration)
        {
            var globalPermitLimit =
                configuration.GetValue<int>(
                    "RateLimitSettings:Global:PermitLimit");

            var globalWindow =
                configuration.GetValue<int>(
                    "RateLimitSettings:Global:WindowSeconds");

            var authPermitLimit =
                configuration.GetValue<int>(
                    "RateLimitSettings:Auth:PermitLimit");

            var authWindow =
                configuration.GetValue<int>(
                    "RateLimitSettings:Auth:WindowSeconds");

            var otpPermitLimit =
                configuration.GetValue<int>(
                    "RateLimitSettings:Otp:PermitLimit");

            var otpWindow =
                configuration.GetValue<int>(
                    "RateLimitSettings:Otp:WindowSeconds");

            var orderPermitLimit =
                configuration.GetValue<int>(
                    "RateLimitSettings:Order:PermitLimit");

            var orderWindow =
                configuration.GetValue<int>(
                    "RateLimitSettings:Order:WindowSeconds");

            services.AddRateLimiter(options =>
            {
                /*
                 * GLOBAL LIMIT
                 *
                 * Authenticated user -> User ID/name
                 * Anonymous user     -> IP address
                 */
                options.GlobalLimiter =
                    PartitionedRateLimiter.Create<HttpContext, string>(
                        context =>
                        {
                            var partitionKey =
                                context.User.Identity?.IsAuthenticated == true
                                    ? context.User.Identity.Name ?? "authenticated"
                                    : context.Connection.RemoteIpAddress?.ToString()
                                      ?? "anonymous";

                            return RateLimitPartition.GetFixedWindowLimiter(
                                partitionKey,
                                _ => new FixedWindowRateLimiterOptions
                                {
                                    PermitLimit = globalPermitLimit,
                                    Window = TimeSpan.FromSeconds(globalWindow),
                                    QueueLimit = 0,
                                    AutoReplenishment = true
                                });
                        });

                options.AddFixedWindowLimiter(
                    AuthPolicy,
                    limiter =>
                    {
                        limiter.PermitLimit = authPermitLimit;
                        limiter.Window =
                            TimeSpan.FromSeconds(authWindow);

                        limiter.QueueLimit = 0;
                        limiter.AutoReplenishment = true;
                    });

                options.AddFixedWindowLimiter(
                    OtpPolicy,
                    limiter =>
                    {
                        limiter.PermitLimit = otpPermitLimit;
                        limiter.Window =
                            TimeSpan.FromSeconds(otpWindow);

                        limiter.QueueLimit = 0;
                        limiter.AutoReplenishment = true;
                    });

                options.AddFixedWindowLimiter(
                    OrderPolicy,
                    limiter =>
                    {
                        limiter.PermitLimit = orderPermitLimit;
                        limiter.Window =
                            TimeSpan.FromSeconds(orderWindow);

                        limiter.QueueLimit = 0;
                        limiter.AutoReplenishment = true;
                    });

                /*
                 * IMPORTANT:
                 * Explicitly return HTTP 429.
                 */
                options.RejectionStatusCode =
                    StatusCodes.Status429TooManyRequests;

                options.OnRejected = async (context, cancellationToken) =>
                {
                    if (context.Lease.TryGetMetadata(
                            MetadataName.RetryAfter,
                            out var retryAfter))
                    {
                        context.HttpContext.Response.Headers.RetryAfter =
                            ((int)retryAfter.TotalSeconds).ToString();
                    }

                    context.HttpContext.Response.ContentType =
                        "application/json";

                    await context.HttpContext.Response.WriteAsJsonAsync(
                        new
                        {
                            success = false,
                            message =
                                "Too many requests. Please try again later."
                        },
                        cancellationToken);
                };
            });

            return services;
        }

        public static IApplicationBuilder UseRateLimitPolicy(
            this IApplicationBuilder app)
        {
            return app.UseRateLimiter();
        }
    }
}
