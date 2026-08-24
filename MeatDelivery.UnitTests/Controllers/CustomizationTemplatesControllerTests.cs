using System.Collections.Generic;
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

        [Fact]
        public async Task GetCustomizationTemplates_WhenCalled_ReturnsOkObjectResult()
        {
            // Arrange
            var query = new GetCustomizationTemplatesQueryDto { PageNumber = 1, PageSize = 10, Search = "Fish" };
            var pagedResponse = new PagedResponse<List<CustomizationTemplateDto>>
            {
                Success = true,
                Message = "Customization templates retrieved successfully.",
                Data = new List<CustomizationTemplateDto>
                {
                    new() { CustomizationTemplateId = 1, DocNo = "CTP0000000001", TemplateNameEn = "Fish Customization" }
                },
                PageNumber = 1,
                PageSize = 10,
                TotalRecords = 1
            };

            _serviceMock.Setup(s => s.GetCustomizationTemplatesAsync(query, It.IsAny<CancellationToken>()))
                .ReturnsAsync(pagedResponse);

            // Act
            var actionResult = await _controller.GetCustomizationTemplates(query, CancellationToken.None);

            // Assert
            var okResult = Assert.IsType<OkObjectResult>(actionResult);
            var response = Assert.IsType<PagedResponse<List<CustomizationTemplateDto>>>(okResult.Value);
            Assert.True(response.Success);
            Assert.Equal(1, response.TotalRecords);
            Assert.Single(response.Data!);
        }
    }
}
