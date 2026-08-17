using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using MeatDelivery.Api.Extensions;
using MeatDelivery.Application.DTOs.Admin;
using MeatDelivery.Application.Interfaces.Admin;

namespace MeatDelivery.Api.Controllers.Admin
{
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/admin")]
    [Authorize(Roles = "SUPER_ADMIN")]
    public class AdminUserController : BaseApiController
    {
        private readonly IAdminUserService _adminUserService;

        public AdminUserController(IAdminUserService adminUserService)
        {
            _adminUserService = adminUserService;
        }

      
        [HttpPost("saveAdminUser")]
        public async Task<IActionResult> SaveAdminUser(
            [FromBody] SaveAdminUserDto request,
            CancellationToken cancellationToken)
        {
            var currentAdminUserId = HttpContext.GetUserId();
            var response = await _adminUserService.SaveAdminUserAsync(request, currentAdminUserId, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;

            if (!response.Success)
            {
                return BadRequest(response);
            }

            return Ok(response);
        }

        /// <summary>
        /// Retrieves a paginated and filterable list of all admin/staff users.
        /// </summary>
        [HttpGet("adminUsers")]
        public async Task<IActionResult> GetAdminUsers(
            [FromQuery] GetAdminUsersQueryDto query,
            CancellationToken cancellationToken)
        {
            var response = await _adminUserService.GetAdminUsersAsync(query, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }

        /// <summary>
        /// Retrieves the detailed profile and assigned roles of a specific admin user by ID.
        /// </summary>
        [HttpGet("adminUser/{id:long}")]
        public async Task<IActionResult> GetAdminUserById(
            [FromRoute] long id,
            CancellationToken cancellationToken)
        {
            var response = await _adminUserService.GetAdminUserByIdAsync(id, cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;

            if (!response.Success)
            {
                return NotFound(response);
            }

            return Ok(response);
        }

        /// <summary>
        /// Retrieves the list of available admin roles in the system for dropdown selection.
        /// </summary>
        [HttpGet("roles")]
        public async Task<IActionResult> GetAdminRoles(CancellationToken cancellationToken)
        {
            var response = await _adminUserService.GetAdminRolesAsync(cancellationToken);
            response.TraceId = HttpContext.TraceIdentifier;
            return Ok(response);
        }
    }
}
