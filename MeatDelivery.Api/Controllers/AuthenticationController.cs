using Asp.Versioning;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using MeatDelivery.Api.Extensions;
using MeatDelivery.Application.DTOs.Auth;
using MeatDelivery.Application.Interfaces.Authentication;
using MeatDelivery.Application.Interfaces.Storage;
using System.Security.Claims;

namespace MeatDelivery.Api.Controllers
{
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/auth")]
    [EnableRateLimiting(RateLimitExtensions.AuthPolicy)]
    public class AuthenticationController : BaseApiController
    {
        private readonly IAuthenticationService _authenticationService;
        private readonly IFileStorageService _fileStorageService;

        public AuthenticationController(
            IAuthenticationService authenticationService,
            IFileStorageService fileStorageService)
        {
            _authenticationService = authenticationService;
            _fileStorageService = fileStorageService;
        }

        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<IActionResult> Login([FromBody] LoginRequestDto request, CancellationToken cancellationToken)
        {
            var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "Unknown";
            var userAgent = Request.Headers.UserAgent.ToString();

            var response = await _authenticationService.LoginAsync(request, ipAddress, userAgent, cancellationToken);
            return Success(response);
        }

        [HttpPost("refresh")]
        [AllowAnonymous]
        public async Task<IActionResult> Refresh([FromBody] RefreshTokenRequestDto request, CancellationToken cancellationToken)
        {
            var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "Unknown";

            var response = await _authenticationService.RefreshTokenAsync(request, ipAddress, cancellationToken);
            return Success(response);
        }

        [HttpPost("logout")]
        [Authorize]
        public async Task<IActionResult> Logout([FromBody] LogoutRequestDto request, CancellationToken cancellationToken)
        {
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(userIdString, out var userId))
                return Unauthorized();

            await _authenticationService.LogoutAsync(userId, request.RefreshToken, cancellationToken);
            return Success(new { Message = "Logged out successfully" });
        }

        [HttpGet("me")]
        [Authorize]
        public async Task<IActionResult> GetCurrentUser(CancellationToken cancellationToken)
        {
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(userIdString, out var userId))
                return Unauthorized();

            var user = await _authenticationService.GetCurrentUserAsync(userId, cancellationToken);
            
            if (user == null)
                return NotFound("User not found");

            return Success(user);
        }

        [HttpPost("register")]
        [AllowAnonymous]
        public async Task<IActionResult> Register([FromBody] RegisterRequestDto request, CancellationToken cancellationToken)
        {
            var userId = await _authenticationService.RegisterUserAsync(request, cancellationToken);
            return CreatedResponse(new { UserId = userId }, "User registered successfully");
        }

        [HttpPost("profile-picture")]
        [Authorize]
        public async Task<IActionResult> UploadProfilePicture(IFormFile file, CancellationToken cancellationToken)
        {
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!Guid.TryParse(userIdString, out var userId))
                return Unauthorized();

            if (file == null || file.Length == 0)
                return BadRequest("Please select a valid image file.");

            using var stream = file.OpenReadStream();
            var relativePath = await _fileStorageService.UploadFileAsync(stream, file.FileName, "ProfilePictures", cancellationToken);

            var fileUrl = $"{Request.Scheme}://{Request.Host}/{relativePath}";
            return Success(new { ProfilePictureUrl = fileUrl }, "Profile picture uploaded successfully");
        }
    }
}
