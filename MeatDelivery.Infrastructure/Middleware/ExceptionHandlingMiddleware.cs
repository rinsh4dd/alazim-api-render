using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using MeatDelivery.Shared.Constants;
using MeatDelivery.Shared.Responses;
using System;
using System.Collections.Generic;
using System.Net;
using System.Text.Json;
using System.Threading.Tasks;

namespace MeatDelivery.Infrastructure.Middleware
{
    public class ExceptionHandlingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ExceptionHandlingMiddleware> _logger;

        public ExceptionHandlingMiddleware(
            RequestDelegate next,
            ILogger<ExceptionHandlingMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "Unhandled exception occurred. TraceId: {TraceId}",
                    context.TraceIdentifier);

                await HandleExceptionAsync(context, ex);
            }
        }

        private static Task HandleExceptionAsync(HttpContext context, Exception exception)
        {
            context.Response.ContentType = "application/json";

            var statusCode = exception switch
            {
                UnauthorizedAccessException => HttpStatusCode.Unauthorized,
                KeyNotFoundException => HttpStatusCode.NotFound,
                _ => HttpStatusCode.OK
            };

            context.Response.StatusCode = (int)statusCode;

            var message = exception.Message;

            int status = 0;
            int? interval = null;
            var match = System.Text.RegularExpressions.Regex.Match(message, @"(?:in|wait)\s+(\d+)\s+second", System.Text.RegularExpressions.RegexOptions.IgnoreCase);
            if (match.Success && int.TryParse(match.Groups[1].Value, out int parsedSeconds))
            {
                interval = parsedSeconds;
                status = -1;
            }
            else if (message.Contains("limit reached", StringComparison.OrdinalIgnoreCase) ||
                     message.Contains("Maximum", StringComparison.OrdinalIgnoreCase) ||
                     message.Contains("exceeded", StringComparison.OrdinalIgnoreCase) ||
                     message.Contains("blocked", StringComparison.OrdinalIgnoreCase))
            {
                status = -1;
            }

            var response = new ErrorResponse
            {
                Success = false,
                Status = status,
                Message = message,
                Interval = interval,
                Errors = new List<string> { message },
                TraceId = context.TraceIdentifier
            };

            var json = JsonSerializer.Serialize(response, new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            });

            return context.Response.WriteAsync(json);
        }
    }
}
