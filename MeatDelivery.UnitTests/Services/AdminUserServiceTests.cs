using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Moq;
using MeatDelivery.Application.Common.Security;
using MeatDelivery.Application.DTOs.Admin;
using MeatDelivery.Application.Interfaces.Repositories.Authentication;
using MeatDelivery.Application.Validators.Admin;
using MeatDelivery.Domain.Entities.Authentication;
using MeatDelivery.Domain.Enums;
using MeatDelivery.Infrastructure.Services.Admin;
using Xunit;

namespace MeatDelivery.UnitTests.Services
{
    public class AdminUserServiceTests
    {
        private readonly Mock<IAdminUserRepository> _adminUserRepoMock = new();
        private readonly Mock<IPasswordHasher> _passwordHasherMock = new();
        private readonly SaveAdminUserDtoValidator _validator = new();
        private readonly AdminUserService _service;

        public AdminUserServiceTests()
        {
            _service = new AdminUserService(
                _adminUserRepoMock.Object,
                _passwordHasherMock.Object,
                _validator);
        }

        [Fact]
        public async Task SaveAdminUserAsync_AddMode_ValidRequest_ReturnsSuccessWithDocNoAndRoles()
        {
            // Arrange
            var request = new SaveAdminUserDto
            {
                Mode = AdminUserMode.ADD,
                Email = "manager.dxb@alazima.com",
                Password = "Manager@2026!",
                FirstName = "Ahmed",
                LastName = "Al Mansoori",
                CountryCode = "+971",
                MobileNumber = "501234567",
                AdminStatus = AdminStatus.ACTIVE,
                Roles = new List<string> { "STORE_MANAGER", "ORDER_MANAGER" }
            };

            _passwordHasherMock.Setup(h => h.Hash("Manager@2026!"))
                .Returns("$2a$10$hashedpassword");

            var expectedResponse = new SaveAdminUserResponseDto
            {
                AdminUserId = 2,
                DocType = "ADM1",
                DocNo = "ADM0000002",
                Email = "manager.dxb@alazima.com",
                FirstName = "Ahmed",
                LastName = "Al Mansoori",
                FullName = "Ahmed Al Mansoori",
                CountryCode = "+971",
                MobileNumber = "501234567",
                AdminStatus = "ACTIVE",
                IsDeleted = false,
                Roles = new List<string> { "STORE_MANAGER", "ORDER_MANAGER" },
                CreatedAt = DateTime.UtcNow
            };

            _adminUserRepoMock.Setup(r => r.SaveAdminUserAsync(
                request,
                "$2a$10$hashedpassword",
                "STORE_MANAGER,ORDER_MANAGER",
                1,
                It.IsAny<CancellationToken>()))
                .ReturnsAsync(expectedResponse);

            // Act
            var result = await _service.SaveAdminUserAsync(request, 1);

            // Assert
            Assert.NotNull(result);
            Assert.True(result.Success);
            Assert.Equal("ADM1", result.Data?.DocType);
            Assert.Equal("ADM0000002", result.Data?.DocNo);
            Assert.Equal(2, result.Data?.AdminUserId);
            Assert.Equal("Ahmed Al Mansoori", result.Data?.FullName);
            Assert.Contains("STORE_MANAGER", result.Data?.Roles!);
        }

        [Fact]
        public async Task SaveAdminUserAsync_EditMode_ValidRequest_ReturnsSuccess()
        {
            // Arrange
            var request = new SaveAdminUserDto
            {
                Mode = AdminUserMode.EDIT,
                AdminUserId = 2,
                FirstName = "Ahmed Updated",
                LastName = "Al Mansoori",
                Roles = new List<string> { "STORE_MANAGER" }
            };

            var expectedResponse = new SaveAdminUserResponseDto
            {
                AdminUserId = 2,
                DocType = "ADM1",
                DocNo = "ADM0000002",
                Email = "manager.dxb@alazima.com",
                FirstName = "Ahmed Updated",
                LastName = "Al Mansoori",
                FullName = "Ahmed Updated Al Mansoori",
                AdminStatus = "ACTIVE",
                IsDeleted = false,
                Roles = new List<string> { "STORE_MANAGER" }
            };

            _adminUserRepoMock.Setup(r => r.SaveAdminUserAsync(
                request,
                null,
                "STORE_MANAGER",
                1,
                It.IsAny<CancellationToken>()))
                .ReturnsAsync(expectedResponse);

            // Act
            var result = await _service.SaveAdminUserAsync(request, 1);

            // Assert
            Assert.NotNull(result);
            Assert.True(result.Success);
            Assert.Equal("Ahmed Updated Al Mansoori", result.Data?.FullName);
        }

        [Fact]
        public async Task SaveAdminUserAsync_DeleteMode_ValidRequest_MarksAsDeleted()
        {
            // Arrange
            var request = new SaveAdminUserDto
            {
                Mode = AdminUserMode.DELETE,
                AdminUserId = 2
            };

            var expectedResponse = new SaveAdminUserResponseDto
            {
                AdminUserId = 2,
                DocType = "ADM1",
                DocNo = "ADM0000002",
                Email = "manager.dxb@alazima.com",
                AdminStatus = "SUSPENDED",
                IsDeleted = true,
                DeletedAt = DateTime.UtcNow
            };

            _adminUserRepoMock.Setup(r => r.SaveAdminUserAsync(
                request,
                null,
                null,
                1,
                It.IsAny<CancellationToken>()))
                .ReturnsAsync(expectedResponse);

            // Act
            var result = await _service.SaveAdminUserAsync(request, 1);

            // Assert
            Assert.NotNull(result);
            Assert.True(result.Success);
            Assert.True(result.Data?.IsDeleted);
            Assert.Equal("SUSPENDED", result.Data?.AdminStatus);
        }

        [Fact]
        public async Task SaveAdminUserAsync_AddMode_InvalidEmail_ReturnsFailure()
        {
            // Arrange
            var request = new SaveAdminUserDto
            {
                Mode = AdminUserMode.ADD,
                Email = "not-an-email",
                Password = "Manager@2026!",
                FirstName = "Ahmed",
                Roles = new List<string> { "STORE_MANAGER" }
            };

            // Act
            var result = await _service.SaveAdminUserAsync(request, 1);

            // Assert
            Assert.NotNull(result);
            Assert.False(result.Success);
            Assert.Contains(result.Errors, e => e.Contains("valid email", StringComparison.OrdinalIgnoreCase));
        }

        [Fact]
        public async Task GetAdminUsersAsync_ValidQuery_ReturnsPaginatedList()
        {
            // Arrange
            var query = new GetAdminUsersQueryDto { Page = 1, PageSize = 10 };
            var list = new List<SaveAdminUserResponseDto>
            {
                new() { AdminUserId = 1, DocType = "ADM1", DocNo = "ADM0000001", Email = "admin@alazima.com" },
                new() { AdminUserId = 2, DocType = "ADM1", DocNo = "ADM0000002", Email = "manager@alazima.com" }
            };

            _adminUserRepoMock.Setup(r => r.GetAdminUsersAsync(query, It.IsAny<CancellationToken>()))
                .ReturnsAsync((list, 2));

            // Act
            var result = await _service.GetAdminUsersAsync(query);

            // Assert
            Assert.NotNull(result);
            Assert.True(result.Success);
            Assert.Equal(2, result.Data?.Count);
        }

        [Fact]
        public async Task GetAdminUserByIdAsync_ExistingId_ReturnsUser()
        {
            // Arrange
            var user = new AdminUser
            {
                AdminUserId = 1,
                DocType = "ADM1",
                DocNo = "ADM0000001",
                Email = "admin@alazima.com",
                FirstName = "Super",
                LastName = "Admin",
                AdminStatus = AdminStatus.ACTIVE
            };
            var roles = new List<string> { "SUPER_ADMIN" };

            _adminUserRepoMock.Setup(r => r.GetByIdWithRolesAsync(1, It.IsAny<CancellationToken>()))
                .ReturnsAsync((user, roles));

            // Act
            var result = await _service.GetAdminUserByIdAsync(1);

            // Assert
            Assert.NotNull(result);
            Assert.True(result.Success);
            Assert.Equal("ADM1", result.Data?.DocType);
            Assert.Equal("ADM0000001", result.Data?.DocNo);
            Assert.Equal("admin@alazima.com", result.Data?.Email);
            Assert.Contains("SUPER_ADMIN", result.Data?.Roles!);
        }

        [Fact]
        public async Task GetAdminUserByIdAsync_NonExistingId_ReturnsNotFound()
        {
            // Arrange
            _adminUserRepoMock.Setup(r => r.GetByIdWithRolesAsync(999, It.IsAny<CancellationToken>()))
                .ReturnsAsync(((AdminUser?)null, new List<string>()));

            // Act
            var result = await _service.GetAdminUserByIdAsync(999);

            // Assert
            Assert.NotNull(result);
            Assert.False(result.Success);
            Assert.Equal("Admin user not found.", result.Message);
        }
    }
}
