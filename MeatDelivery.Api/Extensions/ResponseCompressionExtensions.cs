using System.IO.Compression;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.ResponseCompression;
using Microsoft.Extensions.DependencyInjection;

namespace MeatDelivery.Api.Extensions
{
    public static class ResponseCompressionExtensions
    {
        public static IServiceCollection AddGzipCompressionSupport(this IServiceCollection services)
        {
            services.AddResponseCompression(options =>
            {
                options.EnableForHttps = true;
                options.Providers.Add<GzipCompressionProvider>();
            });

            services.Configure<GzipCompressionProviderOptions>(options =>
            {
                options.Level = CompressionLevel.Fastest;
            });

            return services;
        }

        public static IApplicationBuilder UseGzipCompressionSupport(this IApplicationBuilder app)
        {
            return app.UseResponseCompression();
        }
    }
}
