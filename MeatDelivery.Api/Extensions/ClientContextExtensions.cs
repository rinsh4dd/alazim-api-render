using Microsoft.AspNetCore.Http;
using System;
using System.Linq;

namespace MeatDelivery.Api.Extensions
{
    public static class ClientContextExtensions
    {
        public static string GetClientIpAddress(this HttpContext context)
        {
            if (context == null) return "Unknown";

            // 1. Check X-Forwarded-For header (reverse proxy / load balancer)
            if (context.Request.Headers.TryGetValue("X-Forwarded-For", out var forwardedFor))
            {
                var ip = forwardedFor.FirstOrDefault()?.Split(',')[0].Trim();
                if (!string.IsNullOrEmpty(ip)) return ip;
            }

            // 2. Check X-Real-IP header
            if (context.Request.Headers.TryGetValue("X-Real-IP", out var realIp))
            {
                var ip = realIp.FirstOrDefault()?.Trim();
                if (!string.IsNullOrEmpty(ip)) return ip;
            }

            // 3. Fallback to Connection.RemoteIpAddress
            var remoteIp = context.Connection.RemoteIpAddress?.ToString();
            if (remoteIp == "::1") return "127.0.0.1";

            return remoteIp ?? "Unknown";
        }

        public static string GetDeviceId(this HttpContext context)
        {
            if (context == null) return "UNKNOWN_DEVICE";

            // 1. Check custom X-Device-Id HTTP header
            if (context.Request.Headers.TryGetValue("X-Device-Id", out var deviceId) && !string.IsNullOrWhiteSpace(deviceId))
            {
                return deviceId.ToString().Trim();
            }

            return "WEB_CLIENT";
        }

        public static string GetDeviceType(this HttpContext context)
        {
            if (context == null) return "WEB";

            // 1. Check custom X-Device-Type HTTP header
            if (context.Request.Headers.TryGetValue("X-Device-Type", out var deviceType) && !string.IsNullOrWhiteSpace(deviceType))
            {
                return deviceType.ToString().Trim().ToUpperInvariant();
            }

            // 2. Automatically detect from User-Agent
            var userAgent = context.Request.Headers.UserAgent.ToString().ToLowerInvariant();
            if (userAgent.Contains("android")) return "ANDROID";
            if (userAgent.Contains("iphone") || userAgent.Contains("ipad") || userAgent.Contains("ios")) return "IOS";
            if (userAgent.Contains("postmanruntime")) return "POSTMAN";

            return "WEB";
        }

        public static long GetUserId(this HttpContext context)
        {
            if (context?.User == null) return 0;

            var claim = context.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                     ?? context.User.FindFirst("sub")?.Value
                     ?? context.User.FindFirst("userId")?.Value
                     ?? context.User.FindFirst("nameid")?.Value;

            return long.TryParse(claim, out var userId) ? userId : 0;
        }
    }
}
