using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace MeatDelivery.Shared.Responses
{
    public class ApiResponse<T>
    {
        public bool Success { get; set; }
        public int Status { get; set; } = 1;
        public string Message { get; set; } = string.Empty;
        
        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
        public int? Interval { get; set; }

        public T? Data { get; set; }
        public List<string> Errors { get; set; } = new();
        public string? TraceId { get; set; }

        public static ApiResponse<T> SuccessResponse(T data, string message = "Request completed successfully.", string? traceId = null, int? interval = null)
            => new()
            {
                Success = true,
                Status = 1,
                Message = message,
                Interval = interval,
                Data = data,
                TraceId = traceId
            };

        public static ApiResponse<T> FailureResponse(string message, List<string>? errors = null, string? traceId = null, int? interval = null, int status = 0)
            => new()
            {
                Success = false,
                Status = status,
                Message = message,
                Interval = interval,
                Errors = errors ?? new List<string> { message },
                TraceId = traceId
            };
    }
}
