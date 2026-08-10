using MeatDelivery.Application.DTOs.Test;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Test;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace MeatDelivery.Infrastructure.Repositories.Test
{
    /// <summary>
    /// Example of a repository implementation in the Infrastructure layer.
    /// This class implements the ITestRepository interface defined in the Application layer.
    /// It encapsulates all database-specific logic, such as stored procedure names and Dapper execution.
    /// </summary>
    public class TestRepository : ITestRepository
    {
        private readonly IDapperRepository _dapperRepository;

        /// <summary>
        /// The Domain/Action Repository injects the generic IDapperRepository to perform the actual SQL execution.
        /// </summary>
        public TestRepository(IDapperRepository dapperRepository)
        {
            _dapperRepository = dapperRepository;
        }

        public async Task<IEnumerable<SampleUpdateDto>> GetActiveItemsAsync()
        {
            // Example of how to call the generic DapperRepository:
            // return await _dapperRepository.QueryAsync<SampleUpdateDto>("usp_Test_GetActive");
            
            return await Task.FromResult(new List<SampleUpdateDto>());
        }

        public async Task<int> UpdateItemAsync(SampleUpdateDto item)
        {
            // Example of how to pass parameters using anonymous objects:
            // return await _dapperRepository.ExecuteAsync("usp_Test_Update", new { item.Id, item.Name });
            
            return await Task.FromResult(1);
        }

        public async Task<MeatDelivery.Shared.Responses.PagedResponse<IEnumerable<SampleUpdateDto>>> GetPagedItemsAsync(int pageNumber, int pageSize)
        {
            // In a real scenario, you would pass pageNumber and pageSize to the stored procedure.
            // Example:
            // var pagedData = await _dapperRepository.QueryAsync<SampleUpdateDto>("usp_Test_GetPaged", new { PageNumber = pageNumber, PageSize = pageSize });
            
            // For demonstration, we will mock 100 records and paginate them in memory.
            var allItems = new List<SampleUpdateDto>();
            for (int i = 1; i <= 100; i++)
            {
                allItems.Add(new SampleUpdateDto { Id = i, Name = $"Demonstration Item {i}" });
            }

            // Calculate pagination
            var pagedItems = allItems
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .ToList();

            // Return the standardized PagedResponse
            return await Task.FromResult(new MeatDelivery.Shared.Responses.PagedResponse<IEnumerable<SampleUpdateDto>>
            {
                Success = true,
                Message = "Paged data retrieved successfully.",
                PageNumber = pageNumber,
                PageSize = pageSize,
                TotalRecords = allItems.Count, // Total count of records across all pages
                Data = pagedItems
            });
        }
    }
}
