using System;
using System.Threading;
using System.Threading.Tasks;

namespace MeatDelivery.Application.Interfaces.Logging
{
    /// <summary>
    /// Service for logging important database and business activities 
    /// without storing the entire payload of changes.
    /// </summary>
    public interface IActivityLogService
    {
        /// <summary>
        /// Logs a specific action performed in the system.
        /// </summary>
        /// <param name="userId">The ID of the user performing the action (null if system or anonymous).</param>
        /// <param name="activityType">A short string identifying the action (e.g., "UserCreated", "InvoiceUpdated").</param>
        /// <param name="description">A human-readable description of what happened.</param>
        /// <param name="source">The service, controller, or component originating the log.</param>
        /// <param name="referenceId">The ID of the primary entity that was affected (e.g., the User ID or Invoice Number).</param>
        /// <param name="cancellationToken">Cancellation token.</param>
        Task LogActivityAsync(
            Guid? userId, 
            string activityType, 
            string description, 
            string? source = null, 
            string? referenceId = null, 
            CancellationToken cancellationToken = default);
    }
}
