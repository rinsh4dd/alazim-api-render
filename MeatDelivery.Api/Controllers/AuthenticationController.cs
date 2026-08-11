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
     
        [HttpPost("send-otp")]
        [AllowAnonymous]
        [EnableRateLimiting(RateLimitExtensions.OtpPolicy)]
        public async Task<IActionResult> SendOtp([FromBody] SendOtpRequestDto request, CancellationToken cancellationToken)
        {
            var response = await _authenticationService.SendOtpAsync(request, cancellationToken);
            return Success(response, "OTP sent successfully.");
        }

        [HttpPost("verify-otp")]
        [AllowAnonymous]
        public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpRequestDto request, CancellationToken cancellationToken)
        {
            var ipAddress = HttpContext.GetClientIpAddress();
            var deviceId = HttpContext.GetDeviceId();
            var deviceType = HttpContext.GetDeviceType();

            var response = await _authenticationService.AuthenticateWithOtpAsync(request, ipAddress, deviceId, deviceType, cancellationToken);
            return Success(response, "OTP verified successfully.");
        }

        [HttpPost("refresh")]
        [AllowAnonymous]
        public async Task<IActionResult> Refresh([FromBody] RefreshTokenRequestDto request, CancellationToken cancellationToken)
        {
            var ipAddress = HttpContext.GetClientIpAddress();
            var deviceId = HttpContext.GetDeviceId();
            var deviceType = HttpContext.GetDeviceType();

            var response = await _authenticationService.RefreshTokenAsync(request, ipAddress, deviceId, deviceType, cancellationToken);
            return Success(response, "Token refreshed successfully.");
        }


        [HttpPost("logout")]
        [AllowAnonymous]
        public async Task<IActionResult> Logout([FromBody] LogoutRequestDto? request, CancellationToken cancellationToken)
        {
            request ??= new LogoutRequestDto();

            if (string.IsNullOrWhiteSpace(request.RefreshToken) && Request.Cookies.TryGetValue("refreshToken", out var cookieRefreshToken))
            {
                request.RefreshToken = cookieRefreshToken;
            }

            if (!string.IsNullOrWhiteSpace(request.RefreshToken) && !string.IsNullOrWhiteSpace(request.CountryCode) && !string.IsNullOrWhiteSpace(request.MobileNumber))
            {
                await _authenticationService.LogoutAsync(request, cancellationToken);
            }

            Response.Cookies.Delete("accessToken");
            Response.Cookies.Delete("refreshToken");

            return Success(new { Message = "Logged out successfully." });
        }


        [HttpPost("revoke-all-sessions")]
        [Authorize]
        public async Task<IActionResult> RevokeAllSessions(CancellationToken cancellationToken)
        {
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!long.TryParse(userIdString, out var userId))
                return Unauthorized();

            await _authenticationService.RevokeAllSessionsAsync(userId, cancellationToken);
            return Success(new { Message = "All active sessions revoked successfully." });
        }

        [HttpPost("profile-picture")]
        [Authorize]
        public async Task<IActionResult> UploadProfilePicture(IFormFile file, CancellationToken cancellationToken)
        {
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!long.TryParse(userIdString, out var userId))
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
