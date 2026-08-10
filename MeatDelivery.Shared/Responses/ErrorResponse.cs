using System;
using System.Collections.Generic;
using System.Text;

namespace MeatDelivery.Shared.Responses
{
    public class ErrorResponse
    {
        public bool Success { get; set; } = false;
        public string Message { get; set; } = string.Empty;
        public List<string> Errors { get; set; } = new();
        public string? TraceId { get; set; }
    }
}
