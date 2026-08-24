using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Moq;
using MeatDelivery.Application.DTOs.Customization;
using MeatDelivery.Application.Interfaces.Repositories.Customization;
using MeatDelivery.Infrastructure.Services.Customization;
using Xunit;

namespace MeatDelivery.UnitTests.Services
{
    public class TemplateGroupMappingServiceTests
    {
        private readonly Mock<ITemplateGroupMappingRepository> _mappingRepositoryMock = new();
        private readonly TemplateGroupMappingService _service;

        public TemplateGroupMappingServiceTests()
        {
            _service = new TemplateGroupMappingService(_mappingRepositoryMock.Object);
        }

        [Fact]
        public async Task SaveTemplateGroupMappingAsync_InvalidQuery_ReturnsValidationError()
        {
            // Arrange
            var request = new SaveTemplateGroupMappingDto { CustomizationTemplateId = 0 };

            // Act
            var result = await _service.SaveTemplateGroupMappingAsync(request, CancellationToken.None);

            // Assert
            Assert.False(result.Success);
            Assert.Equal("Validation failed.", result.Message);
        }

        [Fact]
        public async Task SaveTemplateGroupMappingAsync_ValidPayload_ReturnsSuccess()
        {
            // Arrange
            var request = new SaveTemplateGroupMappingDto
            {
                CustomizationTemplateId = 1,
                GroupIds = new List<long> { 1, 2, 3 }
            };

            var returnedList = new List<TemplateGroupMappingDto>
            {
                new() { TemplateGroupMappingId = 1, CustomizationTemplateId = 1, CustomizationGroupId = 1, GroupCode = "CUT_TYPE" },
                new() { TemplateGroupMappingId = 2, CustomizationTemplateId = 1, CustomizationGroupId = 2, GroupCode = "CLEANING" },
                new() { TemplateGroupMappingId = 3, CustomizationTemplateId = 1, CustomizationGroupId = 3, GroupCode = "PACKAGING" }
            };

            _mappingRepositoryMock
                .Setup(r => r.SaveTemplateGroupMappingAsync(request, It.IsAny<CancellationToken>()))
                .ReturnsAsync(returnedList);

            // Act
            var result = await _service.SaveTemplateGroupMappingAsync(request, CancellationToken.None);

            // Assert
            Assert.True(result.Success);
            Assert.Equal("Template group mappings updated successfully.", result.Message);
            Assert.Equal(3, result.Data?.Count);
        }

        [Fact]
        public async Task GetTemplateGroupMappingsAsync_ValidQuery_ReturnsPagedResult()
        {
            // Arrange
            var query = new GetTemplateGroupMappingsQueryDto
            {
                PageNumber = 1,
                PageSize = 10,
                CustomizationTemplateId = 1
            };

            var items = new List<TemplateGroupMappingDto>
            {
                new() { TemplateGroupMappingId = 1, CustomizationTemplateId = 1, CustomizationGroupId = 1, GroupCode = "CUT_TYPE" }
            };

            _mappingRepositoryMock
                .Setup(r => r.GetTemplateGroupMappingsAsync(query, It.IsAny<CancellationToken>()))
                .ReturnsAsync((items, 1));

            // Act
            var result = await _service.GetTemplateGroupMappingsAsync(query, CancellationToken.None);

            // Assert
            Assert.True(result.Success);
            Assert.Equal("Template group mappings retrieved successfully.", result.Message);
            Assert.Single(result.Data!);
            Assert.Equal(1, result.TotalRecords);
        }
    }
}
