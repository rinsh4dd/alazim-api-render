using MeatDelivery.Application.DTOs.Auth;
using MeatDelivery.Application.Interfaces;
using MeatDelivery.Application.Interfaces.Repositories.Authentication;
using System;
using System.Collections.Generic;
using System.Text;

namespace MeatDelivery.Infrastructure.Repositories.Authentication
{
    public sealed class UserRepository : IUserRepository
    {
        private readonly IDapperRepository _repository;

        public UserRepository(IDapperRepository repository)
        {
            _repository = repository;
        }

        public async Task<UserLoginDto?> GetByUsernameAsync(
            string username,
            CancellationToken cancellationToken = default)
        {
            return await _repository.QueryFirstOrDefaultAsync<UserLoginDto>(
                "usp_Auth_GetUserByUsername",
                new { Username = username });
        }

        public async Task<UserContextDto?> GetUserContextAsync(
            Guid userId,
            CancellationToken cancellationToken = default)
        {
            return await _repository.QueryMultipleAsync(
                "usp_Auth_GetUserContext",
                async multi =>
                {
                    var userContext = await multi.ReadSingleOrDefaultAsync<UserContextDto>();
                    
                    if (userContext != null)
                    {
                        var roles = await multi.ReadAsync<string>();
                        var permissions = await multi.ReadAsync<string>();
                        
                        userContext.Roles = roles.ToList();
                        userContext.Permissions = permissions.ToList();
                    }

                    return userContext;
                },
                new { UserId = userId });
        }

        public async Task UpdateLastLoginAsync(
            Guid userId,
            CancellationToken cancellationToken = default)
        {
            await _repository.ExecuteAsync(
                "usp_Auth_UpdateLastLogin",
                new { UserId = userId });
        }

        public async Task<Guid> CreateUserAsync(
            CreateUserDto user,
            CancellationToken cancellationToken = default)
        {
            return await _repository.ExecuteScalarAsync<Guid>(
                "usp_Auth_CreateUser",
                new
                {
                    Username = user.Username,
                    Email = user.Email,
                    PasswordHash = user.PasswordHash,
                    FirstName = user.FirstName,
                    LastName = user.LastName,
                    PhoneNumber = user.PhoneNumber,
                    RoleId = user.RoleId
                });
        }
    }
}
