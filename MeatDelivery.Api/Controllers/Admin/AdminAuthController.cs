using System;
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
using MeatDelivery.Application.Interfaces.Storage;

namespace MeatDelivery.Api.Controllers.Admin
{
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/admin/auth")]
    [EnableRateLimiting(RateLimitExtensions.AuthPolicy)]
    public class AdminAuthController : BaseApiController
    {
        private readonly IAdminAuthenticationService _adminAuthService;
        private readonly IFileStorageService _fileStorageService;

        public AdminAuthController(
            IAdminAuthenticationService adminAuthService,
            IFileStorageService fileStorageService)
        {
            _adminAuthService = adminAuthService;
            _fileStorageService = fileStorageService;
        }

        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<IActionResult> Login([FromBody] AdminLoginRequestDto request, CancellationToken cancellationToken)
        {
            var ipAddress = HttpContext.GetClientIpAddress();
            var deviceId = HttpContext.GetDeviceId();
            var userAgent = Request.Headers.UserAgent.ToString();

            var response = await _adminAuthService.LoginAsync(request, ipAddress, deviceId, userAgent, cancellationToken);
            return Success(response, "Admin login successful.");
        }

        [HttpPost("refresh")]
        [AllowAnonymous]
        public async Task<IActionResult> Refresh([FromBody] AdminRefreshTokenRequestDto request, CancellationToken cancellationToken)
        {
            var ipAddress = HttpContext.GetClientIpAddress();
            var deviceId = HttpContext.GetDeviceId();
            var userAgent = Request.Headers.UserAgent.ToString();

            var response = await _adminAuthService.RefreshTokenAsync(request, ipAddress, deviceId, userAgent, cancellationToken);
            return Success(response, "Admin token refreshed successfully.");
        }

        [HttpPost("logout")]
        [AllowAnonymous]
        public async Task<IActionResult> Logout([FromBody] AdminRefreshTokenRequestDto? request, CancellationToken cancellationToken)
        {
            request ??= new AdminRefreshTokenRequestDto();

            if (string.IsNullOrWhiteSpace(request.RefreshToken) && Request.Cookies.TryGetValue("refreshToken", out var cookieRefreshToken))
            {
                request.RefreshToken = cookieRefreshToken;
            }

            if (!string.IsNullOrWhiteSpace(request.RefreshToken))
            {
                await _adminAuthService.LogoutAsync(request.RefreshToken, cancellationToken);
            }

            Response.Cookies.Delete("accessToken");
            Response.Cookies.Delete("refreshToken");

            return Success(new { Message = "Logged out successfully." });
        }

        [HttpGet("me")]
        [Authorize]
        public async Task<IActionResult> GetProfile(CancellationToken cancellationToken)
        {
            var adminIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!long.TryParse(adminIdClaim, out var adminUserId))
                return Unauthorized();

            var profile = await _adminAuthService.GetProfileAsync(adminUserId, cancellationToken);
            return Success(profile);
        }

        [HttpPost("profile-picture")]
        [Authorize]
        public async Task<IActionResult> UploadProfilePicture(IFormFile file, CancellationToken cancellationToken)
        {
            var adminIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!long.TryParse(adminIdClaim, out var adminUserId))
                return Unauthorized();

            if (file == null || file.Length == 0)
                return BadRequest("Please select a valid image file.");

            using var stream = file.OpenReadStream();
            var relativePath = await _fileStorageService.UploadFileAsync(stream, file.FileName, "AdminProfiles", cancellationToken);

            var fileUrl = $"{Request.Scheme}://{Request.Host}/{relativePath}";
            return Success(new { ProfilePictureUrl = fileUrl }, "Profile picture uploaded successfully.");
        }
    }
}
