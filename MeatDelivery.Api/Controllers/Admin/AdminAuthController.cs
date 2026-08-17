using System;
using System.Security.Authentication;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using MeatDelivery.Api.Extensions;
using MeatDelivery.Application.DTOs.Admin;
using MeatDelivery.Application.Interfaces.Authentication;

namespace MeatDelivery.Api.Controllers.Admin
{
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/admin/auth")]
    [EnableRateLimiting(RateLimitExtensions.AuthPolicy)]
    public class AdminAuthController : BaseApiController
    {
        private readonly IAdminAuthenticationService _adminAuthService;

        public AdminAuthController(IAdminAuthenticationService adminAuthService)
        {
            _adminAuthService = adminAuthService;
        }

        /// <summary>
        /// Authenticates an administrator with email and password, issuing an Admin JWT Access Token and Refresh Token.
        /// </summary>
        [HttpPost("login")]
        [AllowAnonymous]
        [ProducesResponseType(typeof(Shared.Responses.ApiResponse<AdminAuthResponseDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(Shared.Responses.ApiResponse<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(Shared.Responses.ApiResponse<object>), StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> Login([FromBody] AdminLoginRequestDto request, CancellationToken cancellationToken)
        {
            try
            {
                var ipAddress = HttpContext.GetClientIpAddress();
                var deviceId = HttpContext.GetDeviceId();
                var userAgent = Request.Headers.UserAgent.ToString();

                var response = await _adminAuthService.LoginAsync(request, ipAddress, deviceId, userAgent, cancellationToken);
                return Success(response, "Admin login successful.");
            }
            catch (InvalidCredentialException ex)
            {
                return Unauthorized(new { message = ex.Message });
            }
            catch (InvalidOperationException ex)
            {
                return Failure(ex.Message);
            }
        }

        /// <summary>
        /// Refreshes an expired Admin JWT Access Token using an active Admin Refresh Token.
        /// </summary>
        [HttpPost("refresh")]
        [AllowAnonymous]
        [ProducesResponseType(typeof(Shared.Responses.ApiResponse<AdminAuthResponseDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(Shared.Responses.ApiResponse<object>), StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> Refresh([FromBody] AdminRefreshTokenRequestDto request, CancellationToken cancellationToken)
        {
            try
            {
                var ipAddress = HttpContext.GetClientIpAddress();
                var deviceId = HttpContext.GetDeviceId();
                var userAgent = Request.Headers.UserAgent.ToString();

                var response = await _adminAuthService.RefreshTokenAsync(request, ipAddress, deviceId, userAgent, cancellationToken);
                return Success(response, "Admin token refreshed successfully.");
            }
            catch (InvalidCredentialException ex)
            {
                return Unauthorized(new { message = ex.Message });
            }
            catch (InvalidOperationException ex)
            {
                return Failure(ex.Message);
            }
        }

        /// <summary>
        /// Revokes the current Admin Refresh Token session.
        /// </summary>
        [HttpPost("logout")]
        [AllowAnonymous]
        [ProducesResponseType(typeof(Shared.Responses.ApiResponse<object>), StatusCodes.Status200OK)]
        public async Task<IActionResult> Logout([FromBody] AdminRefreshTokenRequestDto request, CancellationToken cancellationToken)
        {
            if (!string.IsNullOrWhiteSpace(request?.RefreshToken))
            {
                await _adminAuthService.LogoutAsync(request.RefreshToken, cancellationToken);
            }

            return Success(new { Message = "Logged out successfully." });
        }

        /// <summary>
        /// Gets the profile and assigned roles of the currently authenticated administrator.
        /// </summary>
        [HttpGet("me")]
        [Authorize]
        [ProducesResponseType(typeof(Shared.Responses.ApiResponse<AdminProfileDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetProfile(CancellationToken cancellationToken)
        {
            var adminIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!long.TryParse(adminIdClaim, out var adminUserId))
            {
                return Unauthorized();
            }

            var profile = await _adminAuthService.GetProfileAsync(adminUserId, cancellationToken);
            return Success(profile);
        }
    }
}
