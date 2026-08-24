using Microsoft.AspNetCore.Builder;
using MeatDelivery.Infrastructure.Middleware;
using MeatDelivery.Infrastructure.Logging;

namespace MeatDelivery.Api.Extensions
{
    public static class MiddlewareExtensions
    {
        public static IApplicationBuilder UseCustomMiddleware(this IApplicationBuilder app)
        {
            app.UseMiddleware<CorrelationIdMiddleware>();
            app.UseMiddleware<RequestLoggingMiddleware>();
            app.UseMiddleware<ExceptionHandlingMiddleware>();

            return app;
        }
    }
}
