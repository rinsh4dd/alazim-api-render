using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Serilog.Context;

namespace MeatDelivery.Infrastructure.Logging
{
    public class RequestLoggingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<RequestLoggingMiddleware> _logger;

        public RequestLoggingMiddleware(
            RequestDelegate next,
            ILogger<RequestLoggingMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            // Skip logging static files or swagger assets to avoid clutter
            var path = context.Request.Path.Value ?? string.Empty;
            if (path.StartsWith("/swagger") || path.StartsWith("/scalar") || path.StartsWith("/Uploads") || path.EndsWith(".ico") || path.EndsWith(".js") || path.EndsWith(".css"))
            {
                await _next(context);
                return;
            }

            var stopwatch = Stopwatch.StartNew();
            var correlationId = context.TraceIdentifier;

            // Enable request body buffering so we can read it without draining stream
            context.Request.EnableBuffering();

            var requestBodyText = await ReadRequestBodyAsync(context.Request);

            // Swap response body stream to capture response body payload
            var originalResponseBodyStream = context.Response.Body;
            using var responseBodyStream = new MemoryStream();
            context.Response.Body = responseBodyStream;

            using (LogContext.PushProperty("CorrelationId", correlationId))
            using (LogContext.PushProperty("RequestPath", context.Request.Path))
            using (LogContext.PushProperty("RequestMethod", context.Request.Method))
            {
                try
                {
                    _logger.LogInformation(
                        "📥 HTTP {Method} {Path}{Query} Started | Body: {RequestBody}",
                        context.Request.Method,
                        context.Request.Path,
                        context.Request.QueryString.HasValue ? context.Request.QueryString.Value : string.Empty,
                        string.IsNullOrWhiteSpace(requestBodyText) ? "[empty]" : requestBodyText);

                    await _next(context);

                    stopwatch.Stop();

                    var responseBodyText = await ReadResponseBodyAsync(context.Response);

                    _logger.LogInformation(
                        "📤 HTTP {Method} {Path} Responded {StatusCode} in {ElapsedMilliseconds} ms | Body: {ResponseBody}",
                        context.Request.Method,
                        context.Request.Path,
                        context.Response.StatusCode,
                        stopwatch.ElapsedMilliseconds,
                        string.IsNullOrWhiteSpace(responseBodyText) ? "[empty]" : responseBodyText);

                    // Copy captured response payload back to original HTTP response stream
                    await responseBodyStream.CopyToAsync(originalResponseBodyStream);
                }
                catch (Exception ex)
                {
                    stopwatch.Stop();

                    _logger.LogError(
                        ex,
                        "❌ HTTP {Method} {Path} Failed after {ElapsedMilliseconds} ms",
                        context.Request.Method,
                        context.Request.Path,
                        stopwatch.ElapsedMilliseconds);

                    await responseBodyStream.CopyToAsync(originalResponseBodyStream);
                    throw;
                }
            }
        }

        private static async Task<string> ReadRequestBodyAsync(HttpRequest request)
        {
            if (request.ContentLength == null || request.ContentLength == 0) return string.Empty;
            if (request.HasFormContentType) return "[Form Data / File Upload]";

            request.Body.Position = 0;
            using var reader = new StreamReader(request.Body, Encoding.UTF8, leaveOpen: true);
            var body = await reader.ReadToEndAsync();
            request.Body.Position = 0; // reset for downstream model binding

            if (body.Length > 4096) body = body[..4096] + "... [truncated]";
            return body;
        }

        private static async Task<string> ReadResponseBodyAsync(HttpResponse response)
        {
            response.Body.Seek(0, SeekOrigin.Begin);
            using var reader = new StreamReader(response.Body, Encoding.UTF8, leaveOpen: true);
            var body = await reader.ReadToEndAsync();
            response.Body.Seek(0, SeekOrigin.Begin); // reset position for output stream copy

            if (body.Length > 4096) body = body[..4096] + "... [truncated]";
            return body;
        }
    }
}
