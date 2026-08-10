using System;
using System.Collections.Generic;
using System.Text;

namespace MeatDelivery.Shared.Constants
{
    public static class ResponseMessages
    {
        public const string Success = "Request completed successfully.";
        public const string Created = "Record created successfully.";
        public const string Updated = "Record updated successfully.";
        public const string Deleted = "Record deleted successfully.";
        public const string NotFound = "Record not found.";
        public const string ValidationFailed = "Validation failed.";
        public const string Unauthorized = "Unauthorized access.";
        public const string Forbidden = "Access denied.";
        public const string InternalServerError = "An unexpected error occurred.";
    }
}
