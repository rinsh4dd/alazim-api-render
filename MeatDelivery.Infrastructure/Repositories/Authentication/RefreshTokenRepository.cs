using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Authentication;
using MeatDelivery.Application.Interfaces.Repositories.Authentication;

using System;
using System.Threading;
using System.Threading.Tasks;

namespace MeatDelivery.Infrastructure.Repositories.Authentication;


public sealed class RefreshTokenRepository : IRefreshTokenRepository
{
    private readonly IDapperRepository _repository;

    public RefreshTokenRepository(IDapperRepository repository)
    {
        _repository = repository;
    }

    public async Task SaveAsync(
        Guid sessionId,
        Guid userId,
        string refreshToken,
        DateTime expiresOn,
        string? ipAddress,
        string? userAgent,
        CancellationToken cancellationToken = default)
    {
        await _repository.ExecuteAsync(
            "usp_Auth_SaveRefreshToken",
            new
            {
                SessionId = sessionId,
                UserId = userId,
                RefreshToken = refreshToken,
                ExpiresOn = expiresOn,
                IpAddress = ipAddress,
                UserAgent = userAgent
            });
    }

    public async Task<bool> ValidateAsync(
        Guid userId,
        string refreshToken,
        CancellationToken cancellationToken = default)
    {
        return await _repository.ExecuteScalarAsync<bool>(
            "usp_Auth_ValidateRefreshToken",
            new
            {
                UserId = userId,
                RefreshToken = refreshToken
            });
    }

    public async Task RevokeAsync(
        string refreshToken,
        CancellationToken cancellationToken = default)
    {
        await _repository.ExecuteAsync(
            "usp_Auth_RevokeRefreshToken",
            new
            {
                RefreshToken = refreshToken
            });
    }

    public async Task RevokeAllByUserIdAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        await _repository.ExecuteAsync(
            "usp_Auth_RevokeAllRefreshTokensByUserId",
            new
            {
                UserId = userId
            });
    }
}