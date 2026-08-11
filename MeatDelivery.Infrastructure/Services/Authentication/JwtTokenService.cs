using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using MeatDelivery.Application.Interfaces.Authentication;
using MeatDelivery.Infrastructure.Configurations;

namespace MeatDelivery.Infrastructure.Services.Authentication
{
    public sealed class JwtTokenService : ITokenService
    {
        private readonly JwtSettings _jwtSettings;

        public JwtTokenService(IOptions<JwtSettings> jwtOptions)
        {
            _jwtSettings = jwtOptions.Value;
        }

        public string GenerateAccessTokenForUser(
            long userId,
            string fullName,
            string countryCode,
            string mobileNumber,
            IEnumerable<string> roles,
            long sessionId)
        {
            var key = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(_jwtSettings.SecretKey));

            var credentials = new SigningCredentials(
                key,
                SecurityAlgorithms.HmacSha256);

            var claims = new List<Claim>
            {
                new(JwtRegisteredClaimNames.Sub, userId.ToString()),
                new("mobile_number", $"{countryCode}{mobileNumber}"),
                new("country_code", countryCode),
                new("full_name", fullName ?? string.Empty),
                new("session_id", sessionId.ToString()),
                new(ClaimTypes.NameIdentifier, userId.ToString()),
                new(ClaimTypes.Name, fullName ?? mobileNumber)
            };

            foreach (var role in roles ?? Enumerable.Empty<string>())
                claims.Add(new Claim(ClaimTypes.Role, role));

            var token = new JwtSecurityToken(
                issuer: _jwtSettings.Issuer,
                audience: _jwtSettings.Audience,
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(_jwtSettings.AccessTokenExpiryMinutes),
                signingCredentials: credentials);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        public string GenerateRefreshToken()
        {
            var randomBytes = RandomNumberGenerator.GetBytes(64);
            return Convert.ToBase64String(randomBytes);
        }

        public DateTime GetRefreshTokenExpiryUtc()
        {
            return DateTime.UtcNow.AddDays(_jwtSettings.RefreshTokenExpiryDays);
        }
    }
}
