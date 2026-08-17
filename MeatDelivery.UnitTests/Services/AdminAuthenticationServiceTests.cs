using System;
using System.Collections.Generic;
using System.Security.Authentication;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Options;
using Moq;
using MeatDelivery.Application.Common.Security;
using MeatDelivery.Application.DTOs.Admin;
using MeatDelivery.Application.Interfaces.Authentication;
using MeatDelivery.Application.Interfaces.Repositories.Authentication;
using MeatDelivery.Domain.Entities.Authentication;
using MeatDelivery.Domain.Enums;
using MeatDelivery.Infrastructure.Configurations;
using MeatDelivery.Infrastructure.Services.Authentication;
using Xunit;

namespace MeatDelivery.UnitTests.Services
{
    public class AdminAuthenticationServiceTests
    {
        private readonly Mock<IAdminUserRepository> _adminUserRepoMock = new();
        private readonly Mock<IPasswordHasher> _passwordHasherMock = new();
        private readonly Mock<ITokenService> _tokenServiceMock = new();
        private readonly IOptions<JwtSettings> _jwtOptions = Options.Create(new JwtSettings
        {
            SecretKey = "super_secret_test_key_with_sufficient_length_123456",
            Issuer = "MeatDelivery",
            Audience = "MeatDelivery.Admin",
            AccessTokenExpiryMinutes = 60,
            AdminAccessTokenExpiryMinutes = 1440,
            RefreshTokenExpiryDays = 30
        });

        private readonly AdminAuthenticationService _service;

        public AdminAuthenticationServiceTests()
        {
            _service = new AdminAuthenticationService(
                _adminUserRepoMock.Object,
                _passwordHasherMock.Object,
                _tokenServiceMock.Object,
                _jwtOptions);
        }

        [Fact]
        public async Task LoginAsync_ValidCredentials_ReturnsSuccessWithRolesAndAccessToken()
        {
            // Arrange
            var request = new AdminLoginRequestDto { Email = "admin@alazima.com", Password = "SuperAdmin@2026!" };
            var adminUser = new AdminUser
            {
                AdminUserId = 1,
                DocType = "ADM1",
                DocNo = "ADM0000001",
                Email = "admin@alazima.com",
                PasswordHash = "$2a$10$somehash",
                FirstName = "Super",
                LastName = "Admin",
                AdminStatus = AdminStatus.ACTIVE,
                FailedLoginCount = 0
            };
            var roles = new List<string> { "SUPER_ADMIN" };

            _adminUserRepoMock.Setup(r => r.GetByEmailWithRolesAsync("admin@alazima.com", It.IsAny<CancellationToken>()))
                .ReturnsAsync((adminUser, roles));

            _passwordHasherMock.Setup(h => h.Verify(request.Password, adminUser.PasswordHash))
                .Returns(true);

            _passwordHasherMock.Setup(h => h.NeedsRehash(adminUser.PasswordHash))
                .Returns(false);

            _tokenServiceMock.Setup(t => t.GenerateAccessTokenForAdmin(1, "admin@alazima.com", "Super Admin", roles, 0))
                .Returns("mocked_jwt_access_token");

            // Act
            var result = await _service.LoginAsync(request, "127.0.0.1", "device_1", "TestAgent");

            // Assert
            Assert.NotNull(result);
            Assert.Equal(1, result.AdminUserId);
            Assert.Equal("ADM1", result.DocType);
            Assert.Equal("ADM0000001", result.DocNo);
            Assert.Equal("admin@alazima.com", result.Email);
            Assert.Equal("mocked_jwt_access_token", result.AccessToken);
            Assert.Equal(86400, result.ExpiresIn); // 1440 * 60 = 86400s (1 day)
            Assert.Contains("SUPER_ADMIN", result.Roles);
            _adminUserRepoMock.Verify(r => r.RecordLoginSuccessAsync(1, null, It.IsAny<CancellationToken>()), Times.Once);
        }

        [Fact]
        public async Task LoginAsync_InvalidPassword_ThrowsInvalidCredentialExceptionAndRecordsFailure()
        {
            // Arrange
            var request = new AdminLoginRequestDto { Email = "admin@alazima.com", Password = "WrongPassword" };
            var adminUser = new AdminUser
            {
                AdminUserId = 1,
                Email = "admin@alazima.com",
                PasswordHash = "$2a$10$somehash",
                AdminStatus = AdminStatus.ACTIVE
            };

            _adminUserRepoMock.Setup(r => r.GetByEmailWithRolesAsync("admin@alazima.com", It.IsAny<CancellationToken>()))
                .ReturnsAsync((adminUser, new List<string>()));

            _passwordHasherMock.Setup(h => h.Verify(request.Password, adminUser.PasswordHash))
                .Returns(false);

            _adminUserRepoMock.Setup(r => r.RecordLoginFailureAsync(1, 5, 15, It.IsAny<CancellationToken>()))
                .ReturnsAsync((1, null));

            // Act & Assert
            await Assert.ThrowsAsync<InvalidCredentialException>(() =>
                _service.LoginAsync(request, "127.0.0.1", null, null));

            _adminUserRepoMock.Verify(r => r.RecordLoginFailureAsync(1, 5, 15, It.IsAny<CancellationToken>()), Times.Once);
        }

        [Fact]
        public async Task LoginAsync_LockedAccount_ThrowsInvalidOperationException()
        {
            // Arrange
            var request = new AdminLoginRequestDto { Email = "admin@alazima.com", Password = "SuperAdmin@2026!" };
            var adminUser = new AdminUser
            {
                AdminUserId = 1,
                Email = "admin@alazima.com",
                AdminStatus = AdminStatus.ACTIVE,
                LockedUntil = DateTime.UtcNow.AddMinutes(10)
            };

            _adminUserRepoMock.Setup(r => r.GetByEmailWithRolesAsync("admin@alazima.com", It.IsAny<CancellationToken>()))
                .ReturnsAsync((adminUser, new List<string>()));

            // Act & Assert
            var ex = await Assert.ThrowsAsync<InvalidOperationException>(() =>
                _service.LoginAsync(request, "127.0.0.1", null, null));

            Assert.Contains("locked", ex.Message, StringComparison.OrdinalIgnoreCase);
        }

        [Fact]
        public async Task LoginAsync_NeedsRehash_UpgradesPasswordHash()
        {
            // Arrange
            var request = new AdminLoginRequestDto { Email = "admin@alazima.com", Password = "SuperAdmin@2026!" };
            var adminUser = new AdminUser
            {
                AdminUserId = 1,
                Email = "admin@alazima.com",
                PasswordHash = "$2a$10$oldCostHash",
                AdminStatus = AdminStatus.ACTIVE
            };

            _adminUserRepoMock.Setup(r => r.GetByEmailWithRolesAsync("admin@alazima.com", It.IsAny<CancellationToken>()))
                .ReturnsAsync((adminUser, new List<string> { "SUPER_ADMIN" }));

            _passwordHasherMock.Setup(h => h.Verify(request.Password, adminUser.PasswordHash)).Returns(true);
            _passwordHasherMock.Setup(h => h.NeedsRehash(adminUser.PasswordHash)).Returns(true);
            _passwordHasherMock.Setup(h => h.Hash(request.Password)).Returns("$2a$10$newCostHash");

            _tokenServiceMock.Setup(t => t.GenerateAccessTokenForAdmin(It.IsAny<long>(), It.IsAny<string>(), It.IsAny<string>(), It.IsAny<IEnumerable<string>>(), It.IsAny<long>()))
                .Returns("jwt");

            // Act
            await _service.LoginAsync(request, "127.0.0.1", null, null);

            // Assert
            _adminUserRepoMock.Verify(r => r.RecordLoginSuccessAsync(1, "$2a$10$newCostHash", It.IsAny<CancellationToken>()), Times.Once);
        }
    }
}
