using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace MeatDelivery.Shared.Responses
{
    public class ErrorResponse
    {
        public bool Success { get; set; } = false;
        public int Status { get; set; } = 0;
        public string Message { get; set; } = string.Empty;
        
        [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
        public int? Interval { get; set; }

        public List<string> Errors { get; set; } = new();
        public string? TraceId { get; set; }
    }
}
