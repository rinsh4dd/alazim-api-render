using MeatDelivery.Application.DTOs.Auth;
using System;
using System.Collections.Generic;
using System.Text;

namespace MeatDelivery.Application.Interfaces.Repositories.Authentication
{
    public interface IUserRepository
    {
        Task<UserLoginDto?> GetByUsernameAsync(
            string username,
            CancellationToken cancellationToken = default);

        Task<UserContextDto?> GetUserContextAsync(
            Guid userId,
            CancellationToken cancellationToken = default);

        Task UpdateLastLoginAsync(
            Guid userId,
            CancellationToken cancellationToken = default);

        Task<Guid> CreateUserAsync(
            CreateUserDto user,
            CancellationToken cancellationToken = default);
    }
}
