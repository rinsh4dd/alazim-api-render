using MeatDelivery.Application.DTOs.Test;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace MeatDelivery.Application.Interfaces.Repositories.Test
{
    /// <summary>
    /// Example of an action-specific repository interface.
    /// This belongs in the Application layer, establishing a contract that the 
    /// Infrastructure layer must fulfill, adhering to the Dependency Inversion Principle.
    /// </summary>
    public interface ITestRepository
    {
        /// <summary>
        /// Retrieves a list of active items.
        /// </summary>
        Task<IEnumerable<SampleUpdateDto>> GetActiveItemsAsync();

        /// <summary>
        /// Updates an existing item.
        /// </summary>
        Task<int> UpdateItemAsync(SampleUpdateDto item);

        /// <summary>
        /// Retrieves a paginated list of items.
        /// </summary>
        Task<MeatDelivery.Shared.Responses.PagedResponse<IEnumerable<SampleUpdateDto>>> GetPagedItemsAsync(int pageNumber, int pageSize);
    }
}
