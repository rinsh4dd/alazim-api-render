using System;
using System.Collections.Generic;
using System.Text;

namespace MeatDelivery.Shared.Responses
{
    public class ApiResponse<T>
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public T? Data { get; set; }
        public List<string> Errors { get; set; } = new();
        public string? TraceId { get; set; }

        public static ApiResponse<T> SuccessResponse(T data, string message = "Request completed successfully.", string? traceId = null)
            => new()
            {
                Success = true,
                Message = message,
                Data = data,
                TraceId = traceId
            };

        public static ApiResponse<T> FailureResponse(string message, List<string>? errors = null, string? traceId = null)
            => new()
            {
                Success = false,
                Message = message,
                Errors = errors ?? new List<string>(),
                TraceId = traceId
            };
    }
}
