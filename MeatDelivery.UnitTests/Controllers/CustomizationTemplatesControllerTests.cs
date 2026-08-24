using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Moq;
using MeatDelivery.Api.Controllers.V1.Customization;
using MeatDelivery.Application.DTOs.Customization;
using MeatDelivery.Application.Interfaces.Customization;
using MeatDelivery.Domain.Enums;
using MeatDelivery.Shared.Responses;
using Xunit;

namespace MeatDelivery.UnitTests.Controllers
{
    public class CustomizationTemplatesControllerTests
    {
        private readonly Mock<ICustomizationTemplateService> _serviceMock = new();
        private readonly CustomizationTemplatesController _controller;

        public CustomizationTemplatesControllerTests()
        {
            _controller = new CustomizationTemplatesController(_serviceMock.Object)
            {
                ControllerContext = new ControllerContext
                {
                    HttpContext = new DefaultHttpContext()
                }
            };
        }

        [Fact]
        public async Task SaveCustomizationTemplate_WhenCalled_ReturnsOkObjectResult()
        {
            // Arrange
            var request = new SaveCustomizationTemplateDto
            {
                Mode = Mode.ADD,
                TemplateNameEn = "Fish Customization",
                TemplateNameAr = "تخصيص السمك"
            };

            var apiResponse = ApiResponse<CustomizationTemplateDto>.SuccessResponse(
                new CustomizationTemplateDto { CustomizationTemplateId = 1, DocNo = "CTP0000000001" },
                "Customization template created successfully.");

            _serviceMock.Setup(s => s.SaveCustomizationTemplateAsync(request, It.IsAny<CancellationToken>()))
                .ReturnsAsync(apiResponse);

            // Act
            var actionResult = await _controller.SaveCustomizationTemplate(request, CancellationToken.None);

            // Assert
            var okResult = Assert.IsType<OkObjectResult>(actionResult);
            var response = Assert.IsType<ApiResponse<CustomizationTemplateDto>>(okResult.Value);
            Assert.True(response.Success);
            Assert.Equal("CTP0000000001", response.Data?.DocNo);
        }
    }
}
