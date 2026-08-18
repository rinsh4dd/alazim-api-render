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
        public async Task SaveAdminUserAsync_AddMode_ValidRequest_ReturnsSuccessWithDocNoAndRole()
        {
            // Arrange
            var request = new SaveAdminUserDto
            {
                Mode = Mode.ADD,
                Email = "manager.dxb@alazima.com",
                Password = "Manager@2026!",
                FirstName = "Ahmed",
                LastName = "Al Mansoori",
                CountryCode = "+971",
                MobileNumber = "501234567",
                Nationality = "Emirati",
                Dob = new DateTime(1990, 5, 15),
                Address = "Dubai, UAE",
                AdminStatus = "ACTIVE",
                RoleId = 2
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
                Nationality = "Emirati",
                Dob = new DateTime(1990, 5, 15),
                Address = "Dubai, UAE",
                AdminStatus = "ACTIVE",
                IsDeleted = false,
                Role = "ORDER_MANAGER",
                CreatedAt = DateTime.UtcNow
            };

            _adminUserRepoMock.Setup(r => r.SaveAdminUserAsync(
                request,
                "$2a$10$hashedpassword",
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
            Assert.Equal("Emirati", result.Data?.Nationality);
            Assert.Equal(new DateTime(1990, 5, 15), result.Data?.Dob);
            Assert.Equal("Dubai, UAE", result.Data?.Address);
            Assert.Equal("ORDER_MANAGER", result.Data?.Role);
        }

        [Fact]
        public async Task SaveAdminUserAsync_EditMode_ValidRequest_ReturnsSuccess()
        {
            // Arrange
            var request = new SaveAdminUserDto
            {
                Mode = Mode.EDIT,
                AdminUserId = 2,
                FirstName = "Ahmed Updated",
                LastName = "Al Mansoori",
                RoleId = (int)AdminRole.INVENTORY_MANAGER
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
                Role = "INVENTORY_MANAGER"
            };

            _adminUserRepoMock.Setup(r => r.SaveAdminUserAsync(
                request,
                null,
                1,
                It.IsAny<CancellationToken>()))
                .ReturnsAsync(expectedResponse);

            // Act
            var result = await _service.SaveAdminUserAsync(request, 1);

            // Assert
            Assert.NotNull(result);
            Assert.True(result.Success);
            Assert.Equal("Ahmed Updated Al Mansoori", result.Data?.FullName);
            Assert.Equal("INVENTORY_MANAGER", result.Data?.Role);
        }

        [Fact]
        public async Task SaveAdminUserAsync_DeleteMode_ValidRequest_MarksAsDeleted()
        {
            // Arrange
            var request = new SaveAdminUserDto
            {
                Mode = Mode.DELETE,
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
                Mode = Mode.ADD,
                Email = "not-an-email",
                Password = "Manager@2026!",
                FirstName = "Ahmed",
                RoleId = (int)AdminRole.INVENTORY_MANAGER
            };

            // Act
            var result = await _service.SaveAdminUserAsync(request, 1);

            // Assert
            Assert.NotNull(result);
            Assert.False(result.Success);
            Assert.Contains(result.Errors, e => e.Contains("valid email", StringComparison.OrdinalIgnoreCase));
        }

        [Fact]
        public async Task GetAdminUsersAsync_ValidQuery_ReturnsList()
        {
            // Arrange
            var query = new GetAdminUsersQueryDto { RoleId = (int)AdminRole.SUPER_ADMIN };
            var list = new List<SaveAdminUserResponseDto>
            {
                new() { AdminUserId = 1, DocType = "ADM1", DocNo = "ADM0000001", Email = "admin@alazima.com", Role = "SUPER_ADMIN" },
                new() { AdminUserId = 2, DocType = "ADM1", DocNo = "ADM0000002", Email = "manager@alazima.com", Role = "SUPER_ADMIN" }
            };

            _adminUserRepoMock.Setup(r => r.GetAdminUsersAsync(query, It.IsAny<CancellationToken>()))
                .ReturnsAsync(list);

            // Act
            var result = await _service.GetAdminUsersAsync(query);

            // Assert
            Assert.NotNull(result);
            Assert.True(result.Success);
            Assert.Equal(2, result.Data?.Count);
        }

        [Fact]
        public async Task GetAdminUsersAsync_FilterByAdminUserId_ReturnsMatchingUser()
        {
            // Arrange
            var query = new GetAdminUsersQueryDto { AdminUserId = 1 };
            var list = new List<SaveAdminUserResponseDto>
            {
                new() { AdminUserId = 1, DocType = "ADM1", DocNo = "ADM0000001", Email = "admin@alazima.com", Role = "SUPER_ADMIN" }
            };

            _adminUserRepoMock.Setup(r => r.GetAdminUsersAsync(query, It.IsAny<CancellationToken>()))
                .ReturnsAsync(list);

            // Act
            var result = await _service.GetAdminUsersAsync(query);

            // Assert
            Assert.NotNull(result);
            Assert.True(result.Success);
            Assert.Single(result.Data!);
            Assert.Equal("admin@alazima.com", result.Data?[0].Email);
            Assert.Equal("Admin user retrieved successfully.", result.Message);
        }
    }
}
