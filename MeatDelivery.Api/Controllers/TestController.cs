using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MeatDelivery.Application.DTOs.Test;
using MeatDelivery.Application.Interfaces.Repositories.Test;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace MeatDelivery.Api.Controllers
{
    /// <summary>
    /// Reference controller demonstrating standard API patterns in MeatDelivery system.
    /// </summary>
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/[controller]")]
    public class TestController : BaseApiController
    {
        private readonly ITestRepository _testRepository;

        public TestController(ITestRepository testRepository)
        {
            _testRepository = testRepository;
        }

        [HttpGet("public-data")]
        [AllowAnonymous]
        public IActionResult GetPublicData()
        {
            var data = new { Message = "This data is public. Anyone can see it." };
            return Success(data, "Public data retrieved successfully.");
        }

        [HttpGet("secure-data")]
        [Authorize]
        public IActionResult GetSecureData()
        {
            var data = new { Message = "You have a valid token." };
            return Success(data, "Secure data retrieved successfully.");
        }

        [HttpGet("admin-only")]
        [Authorize(Roles = "SuperAdmin,Admin")]
        public IActionResult GetAdminData()
        {
            var data = new { Secret = "Top Secret Admin Financials" };
            return Success(data, "Admin data retrieved.");
        }

        [HttpPost("manage-users-policy")]
        [Authorize(Policy = "CanManageUsers")]
        public IActionResult CreateUserByPolicy([FromBody] SampleUpdateDto request)
        {
            var createdData = new { request.Id, request.Name, Status = "Created" };
            return CreatedResponse(createdData, "User created using policy authorization.");
        }

        [HttpPut("update-data/{id}")]
        [Authorize(Policy = "CanManageSettings")]
        public IActionResult UpdateData(int id, [FromBody] SampleUpdateDto request)
        {
            if (id != request.Id)
                return Failure("Route ID does not match Body ID.");

            if (string.IsNullOrWhiteSpace(request.Name))
                return Failure("Validation failed.", new List<string> { "Name cannot be empty." });

            var updatedData = new { request.Id, request.Name, UpdatedAt = DateTime.UtcNow };
            return Success(updatedData, "Data updated successfully.");
        }

        [HttpGet("db-select")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GetItemsFromDatabase()
        {
            try 
            {
                var items = await _testRepository.GetActiveItemsAsync();
                return Success(items, "Items retrieved from database successfully via Domain Repository.");
            }
            catch (Exception ex)
            {
                return Failure($"Database query failed: {ex.Message}");
            }
        }

        [HttpPost("db-update")]
        [Authorize(Policy = "CanManageSettings")]
        public async Task<IActionResult> UpdateDatabaseRecord([FromBody] SampleUpdateDto request)
        {
            try 
            {
                int affectedRows = await _testRepository.UpdateItemAsync(request);
                
                if (affectedRows == 0) 
                    return Failure("No records were updated. Item may not exist.");
                
                return Success(new { affectedRows }, "Record updated successfully via Domain Repository.");
            }
            catch (Exception ex)
            {
                return Failure($"Database update failed: {ex.Message}");
            }
        }

        [HttpGet("paged-data")]
        [AllowAnonymous]
        public async Task<IActionResult> GetPagedData([FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 10)
        {
            try
            {
                var pagedResponse = await _testRepository.GetPagedItemsAsync(pageNumber, pageSize);
                pagedResponse.TraceId = HttpContext.TraceIdentifier;
                return Ok(pagedResponse);
            }
            catch (Exception ex)
            {
                return Failure($"Pagination query failed: {ex.Message}");
            }
        }
    }
}
