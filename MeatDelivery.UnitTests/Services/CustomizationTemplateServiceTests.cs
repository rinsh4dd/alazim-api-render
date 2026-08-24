using System;
using System.Threading;
using System.Threading.Tasks;
using Moq;
using MeatDelivery.Application.DTOs.Customization;
using MeatDelivery.Application.Interfaces.Repositories.Customization;
using MeatDelivery.Application.Validators.Customization;
using MeatDelivery.Domain.Enums;
using MeatDelivery.Infrastructure.Services.Customization;
using Xunit;

namespace MeatDelivery.UnitTests.Services
{
    public class CustomizationTemplateServiceTests
    {
        private readonly Mock<ICustomizationTemplateRepository> _repoMock = new();
        private readonly SaveCustomizationTemplateDtoValidator _validator = new();
        private readonly CustomizationTemplateService _service;

        public CustomizationTemplateServiceTests()
        {
            _service = new CustomizationTemplateService(
                _repoMock.Object,
                _validator);
        }

        [Fact]
        public async Task SaveCustomizationTemplateAsync_AddMode_ValidRequest_ReturnsSuccess()
        {
            // Arrange
            var request = new SaveCustomizationTemplateDto
            {
                Mode = Mode.ADD,
                TemplateNameEn = "Chicken Customization",
                TemplateNameAr = "تخصيص الدجاج",
                DescriptionEn = "Default chicken cutting options",
                IsActive = true
            };

            var expectedResponse = new CustomizationTemplateDto
            {
                CustomizationTemplateId = 10,
                DocNo = "CTP0000000010",
                DocType = "CTP1",
                TemplateNameEn = "Chicken Customization",
                TemplateNameAr = "تخصيص الدجاج",
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            _repoMock.Setup(r => r.SaveCustomizationTemplateAsync(request, It.IsAny<CancellationToken>()))
                .ReturnsAsync(expectedResponse);

            // Act
            var result = await _service.SaveCustomizationTemplateAsync(request);

            // Assert
            Assert.NotNull(result);
            Assert.True(result.Success);
            Assert.Equal("CTP0000000010", result.Data?.DocNo);
            Assert.Equal("Customization template created successfully.", result.Message);
        }

        [Fact]
        public async Task SaveCustomizationTemplateAsync_AddMode_MissingRequiredFields_ReturnsValidationFailure()
        {
            // Arrange
            var request = new SaveCustomizationTemplateDto
            {
                Mode = Mode.ADD,
                TemplateNameEn = "",
                TemplateNameAr = ""
            };

            // Act
            var result = await _service.SaveCustomizationTemplateAsync(request);

            // Assert
            Assert.NotNull(result);
            Assert.False(result.Success);
            Assert.Equal("Validation failed.", result.Message);
            Assert.Contains(result.Errors, e => e.Contains("English template name is required", StringComparison.OrdinalIgnoreCase));
            Assert.Contains(result.Errors, e => e.Contains("Arabic template name is required", StringComparison.OrdinalIgnoreCase));
        }

        [Fact]
        public async Task SaveCustomizationTemplateAsync_EditMode_InvalidId_ReturnsValidationFailure()
        {
            // Arrange
            var request = new SaveCustomizationTemplateDto
            {
                Mode = Mode.EDIT,
                CustomizationTemplateId = 0
            };

            // Act
            var result = await _service.SaveCustomizationTemplateAsync(request);

            // Assert
            Assert.NotNull(result);
            Assert.False(result.Success);
            Assert.Equal("Validation failed.", result.Message);
            Assert.Contains(result.Errors, e => e.Contains("Valid CustomizationTemplateId is required", StringComparison.OrdinalIgnoreCase));
        }

        [Fact]
        public async Task SaveCustomizationTemplateAsync_DeleteMode_ValidRequest_ReturnsSuccess()
        {
            // Arrange
            var request = new SaveCustomizationTemplateDto
            {
                Mode = Mode.DELETE,
                CustomizationTemplateId = 5
            };

            _repoMock.Setup(r => r.SaveCustomizationTemplateAsync(request, It.IsAny<CancellationToken>()))
                .ReturnsAsync((CustomizationTemplateDto?)null);

            // Act
            var result = await _service.SaveCustomizationTemplateAsync(request);

            // Assert
            Assert.NotNull(result);
            Assert.True(result.Success);
            Assert.Equal("Customization template deleted successfully.", result.Message);
        }
    }
}
