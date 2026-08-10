using MeatDelivery.Application.Interfaces.Authentication;
using MeatDelivery.Infrastructure.Configurations;
using Microsoft.Extensions.Options;

namespace MeatDelivery.Infrastructure.Services.Authentication
{
    public sealed class RefreshTokenService : IRefreshTokenService
    {
        private readonly JwtSettings _jwtSettings;
        private readonly ITokenService _tokenService;

        public RefreshTokenService(
            IOptions<JwtSettings> jwtOptions,
            ITokenService tokenService)
        {
            _jwtSettings = jwtOptions.Value;
            _tokenService = tokenService;
        }

        public string GenerateToken()
        {
            return _tokenService.GenerateRefreshToken();
        }

        public DateTime GetExpiryUtc()
        {
            return DateTime.UtcNow.AddDays(_jwtSettings.RefreshTokenExpiryDays);
        }
    }
}
