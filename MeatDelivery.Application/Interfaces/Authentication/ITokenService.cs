using MeatDelivery.Application.DTOs.Auth;
using System;
using System.Collections.Generic;
using System.Text;

namespace MeatDelivery.Application.Interfaces.Authentication
{
    public interface ITokenService
    {
        string GenerateAccessToken(
            UserContextDto user,
            Guid sessionId);

        string GenerateRefreshToken();

        DateTime GetRefreshTokenExpiryUtc();

        Guid? GetUserIdFromExpiredToken(string accessToken);
    }
}
