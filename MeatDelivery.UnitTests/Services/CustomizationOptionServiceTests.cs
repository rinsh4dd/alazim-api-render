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
    public class CustomizationOptionServiceTests
    {
        private readonly Mock<ICustomizationOptionRepository> _optionRepositoryMock = new();
        private readonly CustomizationOptionService _service;

        public CustomizationOptionServiceTests()
        {
            _service = new CustomizationOptionService(_optionRepositoryMock.Object);
        }

        [Fact]
        public async Task SaveCustomizationOptionAsync_InvalidMode_ReturnsValidationError()
        {
            // Arrange
            var request = new SaveCustomizationOptionDto { Mode = (Mode)99 };

            // Act
            var result = await _service.SaveCustomizationOptionAsync(request, CancellationToken.None);

            // Assert
            Assert.False(result.Success);
            Assert.Equal("Validation failed.", result.Message);
        }

        [Fact]
        public async Task SaveCustomizationOptionAsync_ValidAdd_ReturnsSuccess()
        {
            // Arrange
            var request = new SaveCustomizationOptionDto
            {
                Mode = Mode.ADD,
                CustomizationGroupId = 1,
                OptionCode = "CURRY_CUT",
                OptionNameEn = "Curry Cut",
                OptionNameAr = "تقطيع كاري",
                AdditionalPrice = 0.50m
            };

            var returnedDto = new CustomizationOptionDto
            {
                CustomizationOptionId = 1,
                CustomizationGroupId = 1,
                OptionCode = "CURRY_CUT",
                OptionNameEn = "Curry Cut",
                OptionNameAr = "تقطيع كاري",
                AdditionalPrice = 0.50m,
                IsActive = true
            };

            _optionRepositoryMock
                .Setup(r => r.SaveCustomizationOptionAsync(request, It.IsAny<CancellationToken>()))
                .ReturnsAsync(returnedDto);

            // Act
            var result = await _service.SaveCustomizationOptionAsync(request, CancellationToken.None);

            // Assert
            Assert.True(result.Success);
            Assert.Equal("Customization option created successfully.", result.Message);
            Assert.NotNull(result.Data);
            Assert.Equal(1, result.Data.CustomizationOptionId);
            Assert.Equal("CURRY_CUT", result.Data.OptionCode);
        }

        [Fact]
        public async Task SaveCustomizationOptionAsync_ValidDelete_ReturnsSuccess()
        {
            // Arrange
            var request = new SaveCustomizationOptionDto
            {
                Mode = Mode.DELETE,
                CustomizationOptionId = 1
            };

            _optionRepositoryMock
                .Setup(r => r.SaveCustomizationOptionAsync(request, It.IsAny<CancellationToken>()))
                .ReturnsAsync((CustomizationOptionDto?)null);

            // Act
            var result = await _service.SaveCustomizationOptionAsync(request, CancellationToken.None);

            // Assert
            Assert.True(result.Success);
            Assert.Equal("Customization option deleted successfully.", result.Message);
        }

        [Fact]
        public async Task GetCustomizationOptionsAsync_ValidQuery_ReturnsPagedResult()
        {
            // Arrange
            var query = new GetCustomizationOptionsQueryDto
            {
                PageNumber = 1,
                PageSize = 10,
                Search = "CURRY"
            };

            var items = new List<CustomizationOptionDto>
            {
                new()
                {
                    CustomizationOptionId = 1,
                    CustomizationGroupId = 1,
                    OptionCode = "CURRY_CUT",
                    OptionNameEn = "Curry Cut",
                    AdditionalPrice = 0.50m
                }
            };

            _optionRepositoryMock
                .Setup(r => r.GetCustomizationOptionsAsync(query, It.IsAny<CancellationToken>()))
                .ReturnsAsync((items, 1));

            // Act
            var result = await _service.GetCustomizationOptionsAsync(query, CancellationToken.None);

            // Assert
            Assert.True(result.Success);
            Assert.Equal("Customization options retrieved successfully.", result.Message);
            Assert.Single(result.Data!);
            Assert.Equal(1, result.TotalRecords);
        }
    }
}
