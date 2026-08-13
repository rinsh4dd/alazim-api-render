using System;
using System.Collections.Generic;

namespace MeatDelivery.Application.Interfaces.Authentication
{
    public interface ITokenService
    {
        string GenerateAccessTokenForUser(
            long userId,
            string fullName,
            string countryCode,
            string mobileNumber,
            IEnumerable<string>? roles = null,
            long sessionId = 0);

        string GenerateRefreshToken();

        string HashRefreshToken(string refreshToken);

        DateTime GetRefreshTokenExpiryUtc();
    }
}
