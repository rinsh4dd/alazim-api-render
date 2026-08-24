using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Moq;
using MeatDelivery.Application.DTOs.Customization;
using MeatDelivery.Application.Interfaces.Repositories.Customization;
using MeatDelivery.Domain.Enums;
using MeatDelivery.Infrastructure.Services.Customization;
using Xunit;

namespace MeatDelivery.UnitTests.Services
{
    public class CustomizationGroupServiceTests
    {
        private readonly Mock<ICustomizationGroupRepository> _repoMock = new();
        private readonly CustomizationGroupService _service;

        public CustomizationGroupServiceTests()
        {
            _service = new CustomizationGroupService(_repoMock.Object);
        }

        [Fact]
        public async Task SaveCustomizationGroupAsync_AddMode_ValidRequest_ReturnsSuccess()
        {
            // Arrange
            var request = new SaveCustomizationGroupDto
            {
                Mode = Mode.ADD,
                GroupCode = "CUT_TYPE",
                GroupNameEn = "Cut Type",
                GroupNameAr = "نوع التقطيع",
                IsAdditionalPriceAvailable = true,
                IsActive = true
            };

            var expected = new CustomizationGroupDto
            {
                CustomizationGroupId = 1,
                GroupCode = "CUT_TYPE",
                GroupNameEn = "Cut Type",
                GroupNameAr = "نوع التقطيع",
                IsAdditionalPriceAvailable = true,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            _repoMock.Setup(r => r.SaveCustomizationGroupAsync(request, It.IsAny<CancellationToken>()))
                .ReturnsAsync(expected);

            // Act
            var result = await _service.SaveCustomizationGroupAsync(request);

            // Assert
            Assert.NotNull(result);
            Assert.True(result.Success);
            Assert.Equal("CUT_TYPE", result.Data?.GroupCode);
            Assert.Equal("Customization group created successfully.", result.Message);
        }

        [Fact]
        public async Task SaveCustomizationGroupAsync_AddMode_MissingRequiredFields_ReturnsValidationFailure()
        {
            // Arrange
            var request = new SaveCustomizationGroupDto
            {
                Mode = Mode.ADD,
                GroupCode = "",
                GroupNameEn = "",
                GroupNameAr = ""
            };

            // Act
            var result = await _service.SaveCustomizationGroupAsync(request);

            // Assert
            Assert.NotNull(result);
            Assert.False(result.Success);
            Assert.Equal("Validation failed.", result.Message);
            Assert.Contains(result.Errors, e => e.Contains("Group code is required", StringComparison.OrdinalIgnoreCase));
        }

        [Fact]
        public async Task SaveCustomizationGroupAsync_DeleteMode_ValidRequest_ReturnsSuccess()
        {
            // Arrange
            var request = new SaveCustomizationGroupDto
            {
                Mode = Mode.DELETE,
                CustomizationGroupId = 5
            };

            _repoMock.Setup(r => r.SaveCustomizationGroupAsync(request, It.IsAny<CancellationToken>()))
                .ReturnsAsync((CustomizationGroupDto?)null);

            // Act
            var result = await _service.SaveCustomizationGroupAsync(request);

            // Assert
            Assert.NotNull(result);
            Assert.True(result.Success);
            Assert.Equal("Customization group deleted successfully.", result.Message);
        }

        [Fact]
        public async Task GetCustomizationGroupsAsync_ValidQuery_ReturnsPagedResult()
        {
            // Arrange
            var query = new GetCustomizationGroupsQueryDto { PageNumber = 1, PageSize = 10, Search = "CUT" };
            var list = new List<CustomizationGroupDto>
            {
                new() { CustomizationGroupId = 1, GroupCode = "CUT_TYPE", GroupNameEn = "Cut Type" }
            };

            _repoMock.Setup(r => r.GetCustomizationGroupsAsync(query, It.IsAny<CancellationToken>()))
                .ReturnsAsync((list, 1));

            // Act
            var result = await _service.GetCustomizationGroupsAsync(query);

            // Assert
            Assert.NotNull(result);
            Assert.True(result.Success);
            Assert.Equal(1, result.TotalRecords);
            Assert.Equal(1, result.PageNumber);
            Assert.Equal(10, result.PageSize);
            Assert.Single(result.Data!);
            Assert.Equal("CUT_TYPE", result.Data?[0].GroupCode);
        }
    }
}
